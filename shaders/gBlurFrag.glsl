#version 330 core

// 输入纹理
uniform sampler2D u_Texture;

// 屏幕坐标
in vec2 v_TexCoord;

// 输出颜色
out vec4 FragColor;

// 高斯模糊的权重
const float weights[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

void main()
{
    // 获取当前纹理坐标
    vec2 tex_offset = 1.0 / textureSize(u_Texture, 0); // 获取纹理大小
    vec3 result = texture(u_Texture, v_TexCoord).rgb * weights[0]; // 当前像素的权重

    // 水平方向的模糊
    for(int i = 1; i < 5; ++i)
    {
        result += texture(u_Texture, v_TexCoord + vec2(tex_offset.x * i, 0.0)).rgb * weights[i];
        result += texture(u_Texture, v_TexCoord - vec2(tex_offset.x * i, 0.0)).rgb * weights[i];
    }

    // 垂直方向的模糊
    for(int i = 1; i < 5; ++i)
    {
        result += texture(u_Texture, v_TexCoord + vec2(0.0, tex_offset.y * i)).rgb * weights[i];
        result += texture(u_Texture, v_TexCoord - vec2(0.0, tex_offset.y * i)).rgb * weights[i];
    }

    // 输出最终颜色
    FragColor = vec4(result, 1.0);
}
