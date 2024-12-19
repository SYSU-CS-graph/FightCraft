extends VoxelGeneratorScript

var noise := FastNoiseLite.new()

func _ready():
	noise.frequency = 1.0/128.0
	noise.fractal_octaves = 4

func _generate_block(out_buffer: VoxelBuffer, origin_in_voxels: Vector3i, lod: int):
	var origin_height := origin_in_voxels.y
	for x in 16:
		for z in 16:
			var relative_height = get_height(x+origin_in_voxels.x, z+origin_in_voxels.z) - origin_height
			if relative_height >= 16:
				out_buffer.fill_area(1, Vector3i(x,0,z), Vector3i(x + 1, 16, z + 1), VoxelBuffer.CHANNEL_TYPE) 
			elif relative_height >= 0:
				out_buffer.fill_area(1, Vector3i(x,0,z), Vector3i(x + 1, relative_height+1, z + 1), VoxelBuffer.CHANNEL_TYPE) 
				out_buffer.set_voxel(2, x, relative_height, z, VoxelBuffer.CHANNEL_TYPE)
func get_height(x, z):
	return noise.get_noise_2d(x, z) * 60
