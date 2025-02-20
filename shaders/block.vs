#version 330 core

layout(location=0) in int data;

out vec4 v_color;
out vec3 v_normal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;
uniform ivec3 chunk_pos;

void main() {
	vec3 a_position = vec3(
		data & 63,
		(data & 4032) >> 6,
		(data & 258048) >> 12
	);

	int a_color_data = (data & 1835008) >> 18;
	vec3 a_color;
	if (a_color_data == 0) a_color = vec3(1, 0, 1);
	else if (a_color_data == 1) a_color = vec3(0, .5, 0);
	else if (a_color_data == 2) a_color = vec3(137./255, 81./255, 41./255);
	else if (a_color_data == 3) a_color = vec3(.5, .5, .5);

	int a_normal_data = (data & 14680064) >> 21;
	vec3 a_normal = vec3(0, 0, 0);
	if (a_normal_data == 0) a_normal.x = -1;
	else if (a_normal_data == 1) a_normal.x = +1;
	else if (a_normal_data == 2) a_normal.y = -1;
	else if (a_normal_data == 3) a_normal.y = +1;
	else if (a_normal_data == 4) a_normal.z = -1;
	else if (a_normal_data == 5) a_normal.z = +1;

	vec3 position = a_position + chunk_pos * 32;
	gl_Position = proj * view * model * vec4(position, 1.0);
	v_color = vec4(a_color, 1.0);
	v_normal = a_normal;
}
