package demur

import glm "core:math/linalg/glsl"

Camera :: struct {
	position: glm.vec3,
	front:    glm.vec3,
	up:       glm.vec3,
	yaw:   f64,
	pitch: f64,
}
