package main

import "core:fmt"
import "core:math"
import "core:math/rand"
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
	glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)

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
	vao, vbo, ebo: u32,
	uniforms: gl.Uniforms,
	indices: []u32,
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

	vbo, ebo: u32
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)

	Vertex :: struct {
		pos: glm.vec3,
		col: glm.vec3,
		nor: glm.vec3,
	}

	add_block :: proc(vertices: ^[dynamic]Vertex, indices: ^[dynamic]u32, blocks: [CHUNK_SIZE][CHUNK_SIZE][CHUNK_SIZE]bool, pos: glm.vec3, col: glm.vec3) {
		@(static) idx: u32 = 0

		if (pos.z - 1 >= 0 && !blocks[int(pos.x)][int(pos.y)][int(pos.z - 1)]) || !(pos.z - 1 >= 0) {
			append(vertices, ..[]Vertex{
				{({0, 1, 0} + pos), col, {0, 0, -1}},
				{({0, 0, 0} + pos), col, {0, 0, -1}},
				{({1, 0, 0} + pos), col, {0, 0, -1}},
				{({1, 1, 0} + pos), col, {0, 0, -1}},
			})
			append(indices, ..[]u32{
				0+4*idx, 1+4*idx, 2+4*idx,
				2+4*idx, 3+4*idx, 0+4*idx,
			})
			idx += 1
		}

		if (pos.z + 1 < CHUNK_SIZE && !blocks[int(pos.x)][int(pos.y)][int(pos.z + 1)]) || !(pos.z + 1 < CHUNK_SIZE) {
			append(vertices, ..[]Vertex{
				{({0, 1, 1} + pos), col, {0, 0, +1}},
				{({0, 0, 1} + pos), col, {0, 0, +1}},
				{({1, 0, 1} + pos), col, {0, 0, +1}},
				{({1, 1, 1} + pos), col, {0, 0, +1}},
			})
			append(indices, ..[]u32{
				0+4*idx, 1+4*idx, 2+4*idx,
				2+4*idx, 3+4*idx, 0+4*idx,
			})
			idx += 1
		}

		if (pos.y - 1 >= 0 && !blocks[int(pos.x)][int(pos.y - 1)][int(pos.z)]) || !(pos.y - 1 >= 0) {
			append(vertices, ..[]Vertex{
				{({0, 0, 1} + pos), col, {0, -1, 0}},
				{({0, 0, 0} + pos), col, {0, -1, 0}},
				{({1, 0, 0} + pos), col, {0, -1, 0}},
				{({1, 0, 1} + pos), col, {0, -1, 0}},
			})
			append(indices, ..[]u32{
				0+4*idx, 1+4*idx, 2+4*idx,
				2+4*idx, 3+4*idx, 0+4*idx,
			})
			idx += 1
		}

		if (pos.y + 1 < CHUNK_SIZE && !blocks[int(pos.x)][int(pos.y + 1)][int(pos.z)]) || !(pos.y + 1 < CHUNK_SIZE) {
			append(vertices, ..[]Vertex{
				{({0, 1, 1} + pos), col, {0, +1, 0}},
				{({0, 1, 0} + pos), col, {0, +1, 0}},
				{({1, 1, 0} + pos), col, {0, +1, 0}},
				{({1, 1, 1} + pos), col, {0, +1, 0}},
			})
			append(indices, ..[]u32{
				0+4*idx, 1+4*idx, 2+4*idx,
				2+4*idx, 3+4*idx, 0+4*idx,
			})
			idx += 1
		}

		if (pos.x - 1 >= 0 && !blocks[int(pos.x - 1)][int(pos.y)][int(pos.z)]) || !(pos.x - 1 >= 0) {
			append(vertices, ..[]Vertex{
				{({0, 0, 1} + pos), col, {-1, 0, 0}},
				{({0, 0, 0} + pos), col, {-1, 0, 0}},
				{({0, 1, 0} + pos), col, {-1, 0, 0}},
				{({0, 1, 1} + pos), col, {-1, 0, 0}},
			})
			append(indices, ..[]u32{
				0+4*idx, 1+4*idx, 2+4*idx,
				2+4*idx, 3+4*idx, 0+4*idx,
			})
			idx += 1
		}

		if (pos.x + 1 < CHUNK_SIZE && !blocks[int(pos.x + 1)][int(pos.y)][int(pos.z)]) || !(pos.x + 1 < CHUNK_SIZE) {
			append(vertices, ..[]Vertex{
				{({1, 0, 1} + pos), col, {+1, 0, 0}},
				{({1, 0, 0} + pos), col, {+1, 0, 0}},
				{({1, 1, 0} + pos), col, {+1, 0, 0}},
				{({1, 1, 1} + pos), col, {+1, 0, 0}},
			})
			append(indices, ..[]u32{
				0+4*idx, 1+4*idx, 2+4*idx,
				2+4*idx, 3+4*idx, 0+4*idx,
			})
			idx += 1
		}
	}

	vertices := [dynamic]Vertex{}
	indices := [dynamic]u32{}

	blocks: [CHUNK_SIZE][CHUNK_SIZE][CHUNK_SIZE]bool
	b := 0

	for x in 0..<CHUNK_SIZE {
		for y in 0..<CHUNK_SIZE {
			for z in 0..<CHUNK_SIZE {
				blocks[x][y][z] = rand.float32() < 0.5
			}
		}
	}
	for x in 0..<CHUNK_SIZE {
		for y in 0..<CHUNK_SIZE {
			for z in 0..<CHUNK_SIZE {
				block := blocks[x][y][z]
				if !block do continue
				b += 1
				color: glm.vec3 = rand.float32() < 0.5 ? {137./255, 81./255, 41./255} : {0, .5, 0}
				add_block(&vertices, &indices, blocks, {f32(x), f32(y), f32(z)}, color)
			}
		}
	}

	fmt.printfln("%d vertices = %f mb", len(vertices), f32(len(vertices)*size_of(Vertex))/1024./1024.)
	fmt.printfln("%d indices = %f mb", len(indices), f32(len(indices)*size_of(u32))/1024./1024.)
	fmt.printfln("%d blocks = %d unopt vertices", b, b*4*6)

	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(vertices)*size_of(vertices[0]), raw_data(vertices), gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.EnableVertexAttribArray(2)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, col))
	gl.VertexAttribPointer(2, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, nor))
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices)*size_of(indices[0]), raw_data(indices), gl.STATIC_DRAW)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	return {program, vao, vbo, ebo, uniforms, indices[:]}
}

gl_deinit :: proc(glv: ^GLVars) {
	defer gl.DeleteProgram(glv.program)
	defer delete(glv.uniforms)
	defer gl.DeleteVertexArrays(1, &glv.vao)
	defer gl.DeleteBuffers(1, &glv.vbo)
	defer gl.DeleteBuffers(1, &glv.ebo)
}
