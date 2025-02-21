package demur

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:os"
import "core:encoding/endian"
import "core:time"
import "vendor:glfw"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"

glfw_init :: proc() {
	glfw.WindowHint(glfw.RESIZABLE, glfw.FALSE) // doesnt work??
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	if !glfw.Init() {
		panic("could not init glfw")
	}

	window = glfw.CreateWindow(800, 600, "larry in opengl!", nil, nil)
	glfw.SetWindowPos(window, 1920/2-400, 1080/2-300)
	// glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)

	if window == nil {
		panic("could not create window")
	}

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)
	glfw.SetKeyCallback(window, key_callback)
	glfw.SetCursorPosCallback(window, mouse_callback)
}

glfw_deinit :: proc() {
	defer glfw.Terminate()
	defer glfw.DestroyWindow(window)
}

GLVars :: struct {
	program: u32,
	vao: u32,
	uniforms: gl.Uniforms,
	chunks: []Chunk,
}

gl_init :: proc() -> GLVars {
	gl.load_up_to(4, 6, glfw.gl_set_proc_address)

	program, ok := gl.load_shaders_file("shaders/block.vs", "shaders/block.fs")
	if !ok {
		panic("could not create program")
	}
	gl.UseProgram(program)

	uniforms := gl.get_uniforms_from_program(program)

	vao: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	chunks: [dynamic]Chunk
	timer: time.Stopwatch
	time.stopwatch_start(&timer)
	world_data, ok2 := os.read_entire_file("worlds/test.kvx")
	assert(ok2)
	time.stopwatch_stop(&timer)
	fmt.println(time.stopwatch_duration(timer))

	chunks_len, _ := endian.get_u16(world_data[:2], .Big)
	fmt.println(chunks_len)
	chunk_data_size := 3+CHUNK_SIZE*CHUNK_SIZE*CHUNK_SIZE

	for cidx in 0..<chunks_len {
		time.stopwatch_reset(&timer)
		time.stopwatch_start(&timer)
		defer {
			time.stopwatch_stop(&timer)
			fmt.println(cidx, time.stopwatch_duration(timer))
		}
		chunk_data := world_data[2+int(cidx)*chunk_data_size:][:chunk_data_size]
		// fmt.println(chunk_data[0:3])
		chunk: Chunk
		chunk.position = {i32(chunk_data[0]), i32(chunk_data[1]), i32(chunk_data[2])}
		chunk.blocks = make([][][]Block, CHUNK_SIZE) // @free
		for i in 0..<CHUNK_SIZE {
			chunk.blocks[i] = make([][]Block, CHUNK_SIZE)
			for j in 0..<CHUNK_SIZE {
				chunk.blocks[i][j] = make([]Block, CHUNK_SIZE)
			}
		}
		chunk_init(&chunk)

		chunk_data_idx := 3
		for x in 0..<CHUNK_SIZE {
			for y in 0..<CHUNK_SIZE {
				for z in 0..<CHUNK_SIZE {
					chunk.blocks[x][y][z] = Block(chunk_data[chunk_data_idx])
					defer chunk_data_idx += 1
				}
			}
		}

		// chunk_gen(&chunk)
		chunk_add_blocks(&chunk)
		chunk_setup(&chunk)
		chunk.indices_len = i32(len(chunk.indices))
		delete(chunk.vertices)
		delete(chunk.indices)

		append(&chunks, chunk)
	}

	// for x in 0..<4 {
	// 	for y in 0..<4 {
	// 		for z in 0..<4 {
	// 			chunk: Chunk
	// 			chunk.position = {i32(x), i32(y), i32(z)}
	// 			chunk.blocks = make([][][]Block, CHUNK_SIZE) // @free
	// 			for i in 0..<CHUNK_SIZE {
	// 				chunk.blocks[i] = make([][]Block, CHUNK_SIZE)
	// 				for j in 0..<CHUNK_SIZE {
	// 					chunk.blocks[i][j] = make([]Block, CHUNK_SIZE)
	// 				}
	// 			}
	// 			chunk_init(&chunk)
	// 			chunk_gen(&chunk)
	// 			chunk_add_blocks(&chunk)
	// 			chunk_setup(&chunk)
	// 			chunk.indices_len = i32(len(chunk.indices))
	// 			delete(chunk.vertices)
	// 			delete(chunk.indices)

	// 			append(&chunks, chunk)
	// 		}
	// 	}
	// }

	return {program, vao, uniforms, chunks[:]}
}

gl_deinit :: proc(glv: ^GLVars) {
	defer gl.DeleteProgram(glv.program)
	defer delete(glv.uniforms)
	defer gl.DeleteVertexArrays(1, &glv.vao)
}
