#version 330 core

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
