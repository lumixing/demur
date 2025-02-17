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

	chunk: Chunk
	chunk.position = {}
	chunk.blocks = make([][][]Block, CHUNK_SIZE) // @free
	for i in 0..<CHUNK_SIZE {
		chunk.blocks[i] = make([][]Block, CHUNK_SIZE)
		for j in 0..<CHUNK_SIZE {
			chunk.blocks[i][j] = make([]Block, CHUNK_SIZE)
		}
	}
	chunk_init(&chunk)
	chunk_gen(&chunk)
	chunk_add_blocks(&chunk)

	// fmt.printfln("%d vertices = %f mb", len(vertices), f32(len(vertices)*size_of(Vertex))/1024./1024.)
	// fmt.printfln("%d indices = %f mb", len(indices), f32(len(indices)*size_of(u32))/1024./1024.)
	// fmt.printfln("%d blocks = %d unopt vertices", b, b*4*6)

	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, chunk.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(chunk.vertices)*size_of(chunk.vertices[0]), raw_data(chunk.vertices), gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.EnableVertexAttribArray(2)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, col))
	gl.VertexAttribPointer(2, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, nor))
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, chunk.ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(chunk.indices)*size_of(chunk.indices[0]), raw_data(chunk.indices), gl.STATIC_DRAW)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	return {program, vao, chunk.vbo, chunk.ebo, uniforms, chunk.indices[:]}
}

gl_deinit :: proc(glv: ^GLVars) {
	defer gl.DeleteProgram(glv.program)
	defer delete(glv.uniforms)
	defer gl.DeleteVertexArrays(1, &glv.vao)
	defer gl.DeleteBuffers(1, &glv.vbo)
	defer gl.DeleteBuffers(1, &glv.ebo)
}
