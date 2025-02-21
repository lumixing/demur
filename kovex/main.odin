package kovex

import "core:fmt"
import "core:os"
import "core:encoding/endian"
import "core:math/rand"

Block :: enum(u8) {
	Air,
	Grass,
	Dirt,
	Stone,
}

ENDIAN :: endian.Byte_Order.Big

main :: proc() {
	buffer: [dynamic]u8

	chunks_len: [2]u8
	endian.put_u16(chunks_len[:], ENDIAN, 8*8*8)
	append(&buffer, ..chunks_len[:])

	for cx in 0..<8 {
		for cy in 0..<8 {
			for cz in 0..<8 {
				append(&buffer, u8(cx), u8(cy), u8(cz))
				for x in 0..<32 {
					for y in 0..<32 {
						for z in 0..<32 {
							append(&buffer, u8(rand.choice_enum(Block)))
						}
					}
				}
			}
		}
	}

	fmt.println(len(buffer))
	ok := os.write_entire_file("worlds/test.kvx", buffer[:])
	assert(ok)
}
