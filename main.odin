package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import "vendor:glfw"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"

CHUNK_SIZE :: 32

window: glfw.WindowHandle

camera_pos := glm.vec3{0, 0, 3}
camera_target := glm.vec3{}
camera_dir := glm.normalize(camera_pos - camera_target)
up := glm.vec3{0, 1, 0}
camera_right := glm.normalize(glm.cross(up, camera_dir))
camera_up := glm.cross(camera_dir, camera_right)

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
	vao, vbo, ebo: u32,
	uniforms: gl.Uniforms,
	indices: []u32,
}

gl_init :: proc() -> GLVars {
	gl.load_up_to(4, 6, glfw.gl_set_proc_address)

	program, ok := gl.load_shaders_source(vertex_source, fragment_source)
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
				color: glm.vec3 = rand.float32() < 0.5 ? {137./255, 81./255, 41./255} : {0, .5, 0}
				add_block(&vertices, &indices, blocks, {f32(x), f32(y), f32(z)}, color)
			}
		}
	}
	fmt.println(len(vertices), len(indices))

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

main :: proc() {
	glfw_init()
	defer glfw_deinit()

	glv := gl_init()
	defer gl_deinit(&glv)

	proj := glm.mat4Perspective(45, 800.0/600.0, 0.1, 100)
	gl.UniformMatrix4fv(glv.uniforms["proj"].location, 1, false, raw_data(&proj))
	gl.Enable(gl.DEPTH_TEST)

	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()
		defer glfw.SwapBuffers(window)

		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.BindVertexArray(glv.vao)

		RADIUS :: 64
		cam_x := glm.sin(glfw.GetTime()) * RADIUS
		cam_z := glm.cos(glfw.GetTime()) * RADIUS

		camera_pos = {f32(cam_x), 5, f32(cam_z)}
		view := glm.mat4LookAt(camera_pos, camera_target, camera_up)
		gl.UniformMatrix4fv(glv.uniforms["view"].location, 1, false, raw_data(&view))

		model := glm.identity(glm.mat4)
		// model *= glm.mat4Translate({0, 0, 0})
		gl.UniformMatrix4fv(glv.uniforms["model"].location, 1, false, raw_data(&model))

		gl.DrawElements(gl.TRIANGLES, i32(len(glv.indices)), gl.UNSIGNED_INT, nil)
	}
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_ESCAPE {
		glfw.SetWindowShouldClose(window, true)
	}
}

mouse_callback :: proc "c" (window: glfw.WindowHandle, x_pos, y_pos: f64) {

}

vertex_source := `#version 330 core

layout(location=0) in vec3 a_position;
layout(location=1) in vec3 a_color;
layout(location=2) in vec3 a_normal;

out vec4 v_color;
out vec3 v_normal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

void main() {	
	gl_Position = proj * view * model * vec4(a_position, 1.0);
	v_color = vec4(a_color, 1.0);
	v_normal = a_normal;
}
`

fragment_source := `#version 330 core

in vec4 v_color;
in vec3 v_normal;

out vec4 o_color;

void main() {
	o_color = v_color;

	if (v_normal.x != 0) {
		o_color.xyz /= 1.7;
	} else if (v_normal.z != 0) {
		o_color.xyz /= 2;
	}
}
`