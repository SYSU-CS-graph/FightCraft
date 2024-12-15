shader_type spatial; // 声明为空间着色器，用于3D渲染
render_mode blend_mix, depth_draw_always, cull_back; // 渲染模式设置
// blend_mix：混合模式
// depth_draw_opaque：深度测试
// cull_back：剔除背面

// 材质属性
uniform vec3 albedo : source_color; // 基础颜色
uniform vec3 albedo2 : source_color; // 第二基础颜色，用于 Fresnel 效应混合
uniform float metallic : hint_range(0.0, 1.0) = 0; // 金属度
uniform float roughness : hint_range(0.0, 1.0) = 0.02; // 粗糙度

// 波浪相关参数
uniform sampler2D wave; // 用于生成波浪高度的纹理
uniform sampler2D texture_normal; // 第一张法线贴图
uniform sampler2D texture_normal2; // 第二张法线贴图
uniform vec2 wave_direction = vec2(2.0, 0.0); // 第一组波浪的方向
uniform vec2 wave_direction2 = vec2(0.0, 1.0); // 第二组波浪的方向
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.025; // 波浪移动的时间缩放
uniform float noise_scale = 10.0; // 控制波浪纹理的噪声频率
uniform float height_scale = 0.15; // 控制波浪高度

// 水深颜色
uniform vec4 color_deep : source_color; // 深水颜色
uniform vec4 color_shallow : source_color; // 浅水颜色s
uniform float beers_law = 2.0; // Beer's Law，控制水深的光吸收效果
uniform float depth_offset = -0.75; // 深度偏移量，用于调整深度	//-0.75

// 边缘颜色控制
uniform float edge_scale = 0.1; // 边缘检测阈值
uniform float near = 1.0; // 相机近裁剪平面
uniform float far = 100.0; // 相机远裁剪平面
uniform vec3 edge_color : source_color; // 边缘颜色

// 深度纹理和屏幕纹理
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture; // 深度纹理
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture; // 屏幕纹理
uniform sampler2D depth_texture: hint_depth_texture; // 深度纹理，用于获取深度值
uniform sampler2D screen_texture: hint_screen_texture; // 屏幕纹理，用于混合水体颜色和屏幕内容

// 顶点着色器中传递的变量
varying float height; // 波浪的高度
varying vec3 world_pos; // 当前顶点的世界坐标

// Fresnel 效应计算
float fresnel(float amount, vec3 normal, vec3 view) {
    // 通过法线和视角方向的点积计算 Fresnel 系数
    return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

// 深度线性化函数，将深度值从[0,1]映射到物理深度
float edge(float depth) {
    depth = 2.0 * depth - 1.0; // 将深度值从[0,1]映射到[-1,1]
    return near * far / (far + depth * (near - far)); // 计算线性深度
}

// 顶点着色器
void vertex() {
    // 计算顶点的世界坐标
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // 通过波浪纹理生成动态高度
    height = texture(wave, world_pos.xz / noise_scale + TIME * time_scale).r;

    // 根据高度调整顶点的 y 坐标
    VERTEX.y += height * height_scale;
}



void fragment() {
    // 深度计算
    float depth_texture_2 = texture(depth_texture, SCREEN_UV).r * 2.0 - 1.0; // 从深度纹理获取深度值
	float depth_r = textureLod(depth_texture, SCREEN_UV, 0.0).r; // 从深度纹理获取当前片段深度值
    float depth = PROJECTION_MATRIX[3][2] / (depth_texture_2 + PROJECTION_MATRIX[2][2]); // 转换为裁剪空间深度

    // Beer's Law，用于模拟水深的光吸收
    float depth_blend = exp((depth + VERTEX.z + depth_offset) * -beers_law);
    depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0); // 限制在[0,1]之间
    float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0); // 调整深度混合强度

    // 从屏幕纹理中采样颜色
    vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_power * 2.5).rgb;

    // 根据深度混合深水和浅水的颜色
    vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_power);

    // 综合水的颜色
    vec3 color = mix(screen_color * depth_color, depth_color * 0.25, depth_blend_power * 0.5);

     //边缘深度计算
    float z_depth = edge(texture(DEPTH_TEXTURE, SCREEN_UV).x); // 从深度纹理获取深度值
    float z_pos = edge(FRAGCOORD.z); // 从当前片段的屏幕深度计算
    float z_dif = z_depth - z_pos; // 计算深度差值，用于边缘检测
	
	
	    //// 获取深度值
    //float object_depth = texture(DEPTH_TEXTURE, SCREEN_UV).x; // 场景深度
    //float water_depth = FRAGCOORD.z; // 水面深度
    //// 深度差值
    //float depth_diff = abs(object_depth - water_depth);
    //// 边缘检测 (设置一个阈值)
    //float edge = smoothstep(0.01, 0.05, depth_diff); // 平滑边缘过渡




    // 波浪法线计算
    vec2 time = (TIME * wave_direction) * time_scale; // 第一组波浪移动
    vec2 time2 = (TIME * wave_direction2) * time_scale; // 第二组波浪移动

    // 混合两张法线贴图，生成最终法线
    vec3 normal_blend = mix(texture(texture_normal, world_pos.xz + time).rgb,
                            texture(texture_normal2, world_pos.xz + time2).rgb, 0.5);

    // 计算 Fresnel 效应，用于反射与折射的颜色混合
    float fresnel = fresnel(5.0, NORMAL, VIEW);
    vec3 surface_color = mix(albedo, albedo2, fresnel); // 根据 Fresnel 混合基础颜色

    // 边缘颜色调整
    vec3 depth_color_adj = mix(edge_color, color, step(edge_scale, z_dif)); // 边缘颜色与水体颜色的混合

    // 设置透明度
    float transparency = 1.0 - depth_blend_power; // 基于深度混合计算透明度
    transparency = 0.95; // 固定透明度，稍微调整为半透明
    ALPHA = transparency;
	
	//ALBEDO = depth_color_adj;
    // 输出最终颜色
    ALBEDO = clamp(surface_color + (depth_color_adj * 0.02), vec3(0.0), vec3(1.0)); // 将边界颜色加入水体颜色
    METALLIC = metallic; // 设置金属度
    ROUGHNESS = roughness; // 设置粗糙度
    NORMAL_MAP = normal_blend; // 输出混合后的法线
	//
    // 可视化 z_depth 的值
    //ALBEDO = vec3(texture(DEPTH_TEXTURE, SCREEN_UV).x  ); // 将深度值映射到 [0, 1] 范围，并显示为灰度
	//ALBEDO = vec3(FRAGCOORD.z*1.0); // 显示 UV 坐标为颜色
	//ALBEDO = vec3(depth_r); // 边缘为白色，其他为黑色
}
