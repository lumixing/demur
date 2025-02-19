package main

import "core:math/noise"
import "core:math/rand"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"

CHUNK_SIZE :: 32

Chunk :: struct {
    position: [3]i32,
    blocks: [][][]Block,
    // blocks: [CHUNK_SIZE][CHUNK_SIZE][CHUNK_SIZE]Block, // causes stack problems
    vbo: u32,
    ebo: u32,
    vertices: [dynamic]Vertex,
    indices: [dynamic]u32,
    indices_len: i32, // DrawElements uses signed lengths idk
    vertex_idx: u32,
}

chunk_init :: proc(chunk: ^Chunk) {
    gl.GenBuffers(1, &chunk.vbo)
	gl.GenBuffers(1, &chunk.ebo)
}

chunk_add_block :: proc(chunk: ^Chunk, pos: glm.vec3, col: glm.vec3) {
    if (pos.z - 1 >= 0 && chunk.blocks[int(pos.x)][int(pos.y)][int(pos.z - 1)] == .Air) || !(pos.z - 1 >= 0) {
        append(&chunk.vertices, ..[]Vertex{
            {({0, 1, 0} + pos), col, {0, 0, -1}},
            {({0, 0, 0} + pos), col, {0, 0, -1}},
            {({1, 0, 0} + pos), col, {0, 0, -1}},
            {({1, 1, 0} + pos), col, {0, 0, -1}},
        })
        append(&chunk.indices, ..[]u32{
            0+4*chunk.vertex_idx, 1+4*chunk.vertex_idx, 2+4*chunk.vertex_idx,
            2+4*chunk.vertex_idx, 3+4*chunk.vertex_idx, 0+4*chunk.vertex_idx,
        })
        chunk.vertex_idx += 1
    }

    if (pos.z + 1 < CHUNK_SIZE && chunk.blocks[int(pos.x)][int(pos.y)][int(pos.z + 1)] == .Air) || !(pos.z + 1 < CHUNK_SIZE) {
        append(&chunk.vertices, ..[]Vertex{
            {({0, 1, 1} + pos), col, {0, 0, +1}},
            {({0, 0, 1} + pos), col, {0, 0, +1}},
            {({1, 0, 1} + pos), col, {0, 0, +1}},
            {({1, 1, 1} + pos), col, {0, 0, +1}},
        })
        append(&chunk.indices, ..[]u32{
            0+4*chunk.vertex_idx, 1+4*chunk.vertex_idx, 2+4*chunk.vertex_idx,
            2+4*chunk.vertex_idx, 3+4*chunk.vertex_idx, 0+4*chunk.vertex_idx,
        })
        chunk.vertex_idx += 1
    }

    if (pos.y - 1 >= 0 && chunk.blocks[int(pos.x)][int(pos.y - 1)][int(pos.z)] == .Air) || !(pos.y - 1 >= 0) {
        append(&chunk.vertices, ..[]Vertex{
            {({0, 0, 1} + pos), col, {0, -1, 0}},
            {({0, 0, 0} + pos), col, {0, -1, 0}},
            {({1, 0, 0} + pos), col, {0, -1, 0}},
            {({1, 0, 1} + pos), col, {0, -1, 0}},
        })
        append(&chunk.indices, ..[]u32{
            0+4*chunk.vertex_idx, 1+4*chunk.vertex_idx, 2+4*chunk.vertex_idx,
            2+4*chunk.vertex_idx, 3+4*chunk.vertex_idx, 0+4*chunk.vertex_idx,
        })
        chunk.vertex_idx += 1
    }

    if (pos.y + 1 < CHUNK_SIZE && chunk.blocks[int(pos.x)][int(pos.y + 1)][int(pos.z)] == .Air) || !(pos.y + 1 < CHUNK_SIZE) {
        append(&chunk.vertices, ..[]Vertex{
            {({0, 1, 1} + pos), col, {0, +1, 0}},
            {({0, 1, 0} + pos), col, {0, +1, 0}},
            {({1, 1, 0} + pos), col, {0, +1, 0}},
            {({1, 1, 1} + pos), col, {0, +1, 0}},
        })
        append(&chunk.indices, ..[]u32{
            0+4*chunk.vertex_idx, 1+4*chunk.vertex_idx, 2+4*chunk.vertex_idx,
            2+4*chunk.vertex_idx, 3+4*chunk.vertex_idx, 0+4*chunk.vertex_idx,
        })
        chunk.vertex_idx += 1
    }

    if (pos.x - 1 >= 0 && chunk.blocks[int(pos.x - 1)][int(pos.y)][int(pos.z)] == .Air) || !(pos.x - 1 >= 0) {
        append(&chunk.vertices, ..[]Vertex{
            {({0, 0, 1} + pos), col, {-1, 0, 0}},
            {({0, 0, 0} + pos), col, {-1, 0, 0}},
            {({0, 1, 0} + pos), col, {-1, 0, 0}},
            {({0, 1, 1} + pos), col, {-1, 0, 0}},
        })
        append(&chunk.indices, ..[]u32{
            0+4*chunk.vertex_idx, 1+4*chunk.vertex_idx, 2+4*chunk.vertex_idx,
            2+4*chunk.vertex_idx, 3+4*chunk.vertex_idx, 0+4*chunk.vertex_idx,
        })
        chunk.vertex_idx += 1
    }

    if (pos.x + 1 < CHUNK_SIZE && chunk.blocks[int(pos.x + 1)][int(pos.y)][int(pos.z)] == .Air) || !(pos.x + 1 < CHUNK_SIZE) {
        append(&chunk.vertices, ..[]Vertex{
            {({1, 0, 1} + pos), col, {+1, 0, 0}},
            {({1, 0, 0} + pos), col, {+1, 0, 0}},
            {({1, 1, 0} + pos), col, {+1, 0, 0}},
            {({1, 1, 1} + pos), col, {+1, 0, 0}},
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
				chunk.blocks[x][y][z] = rand.choice_enum(Block)
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
	gl.EnableVertexAttribArray(1)
	gl.EnableVertexAttribArray(2)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, col))
	gl.VertexAttribPointer(2, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, nor))
}

Block :: enum(u8) {
    Air,
    Grass,
    Dirt,
    Stone,
}

block_color :: proc(block: Block) -> glm.vec3 {
    switch block {
    case .Air:   return {0, 0, 0}
    case .Grass: return {0, .5, 0}
    case .Dirt:  return {137./255, 81./255, 41./255}
    case .Stone: return {0.5, 0.5, 0.5}
    }

    return {1, 0, 1}
}

Vertex :: struct {
    pos: glm.vec3,
    col: glm.vec3,
    nor: glm.vec3,
}
