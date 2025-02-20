package demur

import "core:fmt"
import "core:math/noise"
import "core:math/rand"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"

CHUNK_SIZE :: 32

Chunk :: struct {
	position: [3]i32,
	blocks: [][][]Block,
	vbo: u32,
	ebo: u32,
	vertices: [dynamic]u32, // 00000000_NNN_CCC_ZZZZZZ_YYYYYY_XXXXXX
	indices: [dynamic]u32,
	indices_len: i32, // DrawElements uses signed lengths idk
	vertex_idx: u32,
}

chunk_init :: proc(chunk: ^Chunk) {
	gl.GenBuffers(1, &chunk.vbo)
	gl.GenBuffers(1, &chunk.ebo)
}

chunk_add_block :: proc(chunk: ^Chunk, pos: glm.vec3, col: Color) {
	if (pos.z - 1 >= 0 && chunk.blocks[int(pos.x)][int(pos.y)][int(pos.z - 1)] == .Air) || !(pos.z - 1 >= 0) {
		append(&chunk.vertices, ..[]u32{
			vertex_to_data({({0, 1, 0} + pos), col, {0, 0, -1}}),
			vertex_to_data({({0, 0, 0} + pos), col, {0, 0, -1}}),
			vertex_to_data({({1, 0, 0} + pos), col, {0, 0, -1}}),
			vertex_to_data({({1, 1, 0} + pos), col, {0, 0, -1}}),
		})
		append(&chunk.indices, ..[]u32{
			0+4*chunk.vertex_idx, 1+4*chunk.vertex_idx, 2+4*chunk.vertex_idx,
			2+4*chunk.vertex_idx, 3+4*chunk.vertex_idx, 0+4*chunk.vertex_idx,
		})
		chunk.vertex_idx += 1
	}

	if (pos.z + 1 < CHUNK_SIZE && chunk.blocks[int(pos.x)][int(pos.y)][int(pos.z + 1)] == .Air) || !(pos.z + 1 < CHUNK_SIZE) {
		append(&chunk.vertices, ..[]u32{
			vertex_to_data({({0, 1, 1} + pos), col, {0, 0, +1}}),
			vertex_to_data({({0, 0, 1} + pos), col, {0, 0, +1}}),
			vertex_to_data({({1, 0, 1} + pos), col, {0, 0, +1}}),
			vertex_to_data({({1, 1, 1} + pos), col, {0, 0, +1}}),
		})
		append(&chunk.indices, ..[]u32{
			0+4*chunk.vertex_idx, 1+4*chunk.vertex_idx, 2+4*chunk.vertex_idx,
			2+4*chunk.vertex_idx, 3+4*chunk.vertex_idx, 0+4*chunk.vertex_idx,
		})
		chunk.vertex_idx += 1
	}

	if (pos.y - 1 >= 0 && chunk.blocks[int(pos.x)][int(pos.y - 1)][int(pos.z)] == .Air) || !(pos.y - 1 >= 0) {
		append(&chunk.vertices, ..[]u32{
			vertex_to_data({({0, 0, 1} + pos), col, {0, -1, 0}}),
			vertex_to_data({({0, 0, 0} + pos), col, {0, -1, 0}}),
			vertex_to_data({({1, 0, 0} + pos), col, {0, -1, 0}}),
			vertex_to_data({({1, 0, 1} + pos), col, {0, -1, 0}}),
		})
		append(&chunk.indices, ..[]u32{
			0+4*chunk.vertex_idx, 1+4*chunk.vertex_idx, 2+4*chunk.vertex_idx,
			2+4*chunk.vertex_idx, 3+4*chunk.vertex_idx, 0+4*chunk.vertex_idx,
		})
		chunk.vertex_idx += 1
	}

	if (pos.y + 1 < CHUNK_SIZE && chunk.blocks[int(pos.x)][int(pos.y + 1)][int(pos.z)] == .Air) || !(pos.y + 1 < CHUNK_SIZE) {
		append(&chunk.vertices, ..[]u32{
			vertex_to_data({({0, 1, 1} + pos), col, {0, +1, 0}}),
			vertex_to_data({({0, 1, 0} + pos), col, {0, +1, 0}}),
			vertex_to_data({({1, 1, 0} + pos), col, {0, +1, 0}}),
			vertex_to_data({({1, 1, 1} + pos), col, {0, +1, 0}}),
		})
		append(&chunk.indices, ..[]u32{
			0+4*chunk.vertex_idx, 1+4*chunk.vertex_idx, 2+4*chunk.vertex_idx,
			2+4*chunk.vertex_idx, 3+4*chunk.vertex_idx, 0+4*chunk.vertex_idx,
		})
		chunk.vertex_idx += 1
	}

	if (pos.x - 1 >= 0 && chunk.blocks[int(pos.x - 1)][int(pos.y)][int(pos.z)] == .Air) || !(pos.x - 1 >= 0) {
		append(&chunk.vertices, ..[]u32{
			vertex_to_data({({0, 0, 1} + pos), col, {-1, 0, 0}}),
			vertex_to_data({({0, 0, 0} + pos), col, {-1, 0, 0}}),
			vertex_to_data({({0, 1, 0} + pos), col, {-1, 0, 0}}),
			vertex_to_data({({0, 1, 1} + pos), col, {-1, 0, 0}}),
		})
		append(&chunk.indices, ..[]u32{
			0+4*chunk.vertex_idx, 1+4*chunk.vertex_idx, 2+4*chunk.vertex_idx,
			2+4*chunk.vertex_idx, 3+4*chunk.vertex_idx, 0+4*chunk.vertex_idx,
		})
		chunk.vertex_idx += 1
	}

	if (pos.x + 1 < CHUNK_SIZE && chunk.blocks[int(pos.x + 1)][int(pos.y)][int(pos.z)] == .Air) || !(pos.x + 1 < CHUNK_SIZE) {
		append(&chunk.vertices, ..[]u32{
			vertex_to_data({({1, 0, 1} + pos), col, {+1, 0, 0}}),
			vertex_to_data({({1, 0, 0} + pos), col, {+1, 0, 0}}),
			vertex_to_data({({1, 1, 0} + pos), col, {+1, 0, 0}}),
			vertex_to_data({({1, 1, 1} + pos), col, {+1, 0, 0}}),
		})
		append(&chunk.indices, ..[]u32{
			0+4*chunk.vertex_idx, 1+4*chunk.vertex_idx, 2+4*chunk.vertex_idx,
			2+4*chunk.vertex_idx, 3+4*chunk.vertex_idx, 0+4*chunk.vertex_idx,
		})
		chunk.vertex_idx += 1
	}
}

chunk_add_blocks :: proc(chunk: ^Chunk) {
	for x in 0..<CHUNK_SIZE {
		for y in 0..<CHUNK_SIZE {
			for z in 0..<CHUNK_SIZE {
				block := chunk.blocks[x][y][z]
				if block == .Air do continue
				color := block_color(block)
				chunk_add_block(chunk, {f32(x), f32(y), f32(z)}, color)
			}
		}
	}
}

chunk_gen :: proc(chunk: ^Chunk) {
	for x in 0..<CHUNK_SIZE {
		for y in 0..<CHUNK_SIZE {
			for z in 0..<CHUNK_SIZE {
				chunk.blocks[x][y][z] = .Dirt
				// chunk.blocks[x][y][z] = rand.choice_enum(Block)
				// nx := i32(x) + chunk.position.x * 32
				// ny := i32(y) + chunk.position.y * 32
				// nz := i32(z) + chunk.position.z * 32
				// rng := noise.noise_3d_fallback(0, [3]f64{f64(nx)/100, f64(ny)/100, f64(nz)/100})
				// block := Block.Air
				// if rng < 0.4 {
				//     block = .Dirt
				// } else if rng < 0.5 {
				//     block = .Grass
				// }
				// chunk.blocks[x][y][z] = block
			}
		}
	}
}

chunk_setup :: proc(chunk: ^Chunk) {
	gl.BindBuffer(gl.ARRAY_BUFFER, chunk.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(chunk.vertices)*size_of(chunk.vertices[0]), raw_data(chunk.vertices), gl.STATIC_DRAW)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, chunk.ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(chunk.indices)*size_of(chunk.indices[0]), raw_data(chunk.indices), gl.STATIC_DRAW)
}

chunk_use :: proc(chunk: ^Chunk, vao: u32) {
	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, chunk.vbo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, chunk.ebo)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribIPointer(0, 1, gl.UNSIGNED_INT, size_of(u32), 0)
}

Block :: enum(u8) {
	Air,
	Grass,
	Dirt,
	Stone,
}

block_color :: proc(block: Block) -> Color {
	switch block {
	// case .Air:   return {0, 0, 0}
	// case .Grass: return {0, .5, 0}
	// case .Dirt:  return {137./255, 81./255, 41./255}
	// case .Stone: return {0.5, 0.5, 0.5}
	case .Air:   return .Magenta
	case .Grass: return .Green
	case .Dirt:  return .Brown
	case .Stone: return .Gray
	}

	return .Magenta
}

Vertex :: struct {
	pos: glm.vec3,
	col: Color,
	nor: glm.vec3,
}

Color :: enum {
	Magenta = 0,
	Green   = 1,
	Brown   = 2,
	Gray    = 3,
}

vertex_to_data :: proc(vertex: Vertex) -> u32 {
	data: u32

	data |= u32(vertex.pos.x)
	data |= u32(vertex.pos.y) << 6
	data |= u32(vertex.pos.z) << 12

	data |= u32(vertex.col) << 18

	normal_data: u32
	if vertex.nor.x == -1      do normal_data = 0
	else if vertex.nor.x == +1 do normal_data = 1
	else if vertex.nor.y == -1 do normal_data = 2
	else if vertex.nor.y == +1 do normal_data = 3
	else if vertex.nor.z == -1 do normal_data = 4
	else if vertex.nor.z == +1 do normal_data = 5
	data |= normal_data << 21

	return data
}
