#version 330 core

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
