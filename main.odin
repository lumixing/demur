package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import "vendor:glfw"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"

window: glfw.WindowHandle
camera: Camera

main :: proc() {
	glfw_init()
	defer glfw_deinit()

	glv := gl_init()
	defer gl_deinit(&glv)

	camera.position = {16, 16, 64}
	camera.front = {0, 0, -1}
	camera.up = {0, 1, 0}
	camera.yaw = 270

	proj := glm.mat4Perspective(45, 800.0/600.0, 0.1, 1000)
	gl.UniformMatrix4fv(glv.uniforms["proj"].location, 1, false, raw_data(&proj))
	gl.Enable(gl.DEPTH_TEST)

	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()
		defer glfw.SwapBuffers(window)

		if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS {
			camera.position.xz += glm.normalize_vec2(camera.front.xz).xy
		}
		if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS {
			camera.position.xz -= glm.normalize_vec2(camera.front.xz).xy
		}
		if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS {
			camera.position -= glm.normalize(glm.cross(camera.front, camera.up))
		}
		if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS {
			camera.position += glm.normalize(glm.cross(camera.front, camera.up))
		}
		if glfw.GetKey(window, glfw.KEY_SPACE) == glfw.PRESS {
			camera.position += camera.up
		}
		if glfw.GetKey(window, glfw.KEY_LEFT_SHIFT) == glfw.PRESS {
			camera.position -= camera.up
		}

		gl.ClearColor(135./255, 206./255, 235./255, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.BindVertexArray(glv.vao)

		view := glm.mat4LookAt(camera.position, camera.position + camera.front, camera.up)
		gl.UniformMatrix4fv(glv.uniforms["view"].location, 1, false, raw_data(&view))

		model := glm.identity(glm.mat4)
		gl.UniformMatrix4fv(glv.uniforms["model"].location, 1, false, raw_data(&model))

		for &chunk in glv.chunks {
			gl.Uniform3iv(glv.uniforms["chunk_pos"].location, 1, raw_data(&chunk.position))
			chunk_use(&chunk, glv.vao)
			gl.DrawElements(gl.TRIANGLES, chunk.indices_len, gl.UNSIGNED_INT, nil)
		}

	}
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_ESCAPE {
		glfw.SetWindowShouldClose(window, true)
	}
}

mouse_callback :: proc "c" (window: glfw.WindowHandle, x, y: f64) {
	@(static) last_pos: [2]f64
	@(static) first := true

	pos := [2]f64{x, y}

	if first {
		first = false
		last_pos = pos
	}

	offset := pos - last_pos
	offset.y *= -1
	last_pos = pos

	SENS :: 0.1
	offset *= SENS

	camera.yaw += offset.x
	camera.pitch += offset.y
	camera.pitch = clamp(camera.pitch, -89, 89)

	camera.front = {
		f32(glm.cos(glm.radians(camera.yaw)) * glm.cos(glm.radians(camera.pitch))),
		f32(glm.sin(glm.radians(camera.pitch))),
		f32(glm.sin(glm.radians(camera.yaw)) * glm.cos(glm.radians(camera.pitch))),
	}
	camera.front = glm.normalize(camera.front)
}
