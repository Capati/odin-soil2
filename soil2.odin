package soil2

when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmt")
	foreign import _LIB_ {"./lib/soil2.lib", "system:opengl32.lib"}
} else when ODIN_OS == .Linux {
	foreign import _LIB_ {"./lib/soil2.a", "system:GL"}
} else when ODIN_OS == .Darwin {
	foreign import _LIB_ {"./lib/darwin/soil2.a", "system:OpenGL.framework"}
} else when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
	foreign import _LIB_ {"./lib/soil2_wasm.o", "system:GLESv2"}
} else {
	foreign import _LIB_ "system:libsoil2"
}

MAJOR_VERSION :: 1
MINOR_VERSION :: 3
PATCH_LEVEL :: 0

VERSION_NUM :: proc(x, y, z: int) -> int {
	return (x) * 1000 + (y) * 100 + (z)
}

COMPILED_VERSION :: MAJOR_VERSION * 1000 + MINOR_VERSION * 100 * PATCH_LEVEL

VERSION_ATLEAST :: proc(x, y, z: int) -> bool {
	return COMPILED_VERSION >= VERSION_NUM(x, y, z)
}

@(default_calling_convention = "c", link_prefix = "SOIL_")
foreign _LIB_ {
	version :: proc() -> u64 ---
}

// The format of images that may be loaded (force_channels).
//
// - `Auto`: leaves the image in whatever format it was found.
// - `L`: forces the image to load as Luminous (greyscale)
// - `La`: forces the image to load as Luminous with Alpha
// - `Rgb`: forces the image to load as Red Green Blue
// - `Rgba`: forces the image to load as Red Green Blue Alpha
Image_Format :: enum i32 {
	Auto,
	L,
	La,
	Rgb,
	Rgba,
}

// Flags you can pass into `load_OGL_texture()` and `create_OGL_texture()`. (note that if
// `Dds_Load_Direct` is used the rest of the flags with the exception of `Texture_Repeats` will
// be ignored while loading already-compressed DDS files.)
//
// - `Power_Of_Two`: force the image to be POT
// - `Mipmaps`: generate mipmaps for the texture
// - `Texture_Repeats`: otherwise will clamp
// - `Multiply_Alpha`: for using (`.One`, `,One_Minus_Src_Alpha`) blending
// - `Invert_Y`: flip the image vertically
// - `Compress_To_Dxt`: if the card can display them, will convert RGB to DXT1, RGBA to DXT5
// - `Dds_Load_Direct`: will load DDS files directly without any additional processing ( if
//   supported )
// - `Ntsc_Safe_Rgb`: clamps RGB components to the range [16,235]
// - `Co_Cg_Y`: Google YCoCg; RGB=>CoYCg, RGBA=>CoCgAY
// - `Texture_Rectange`: uses `ARB_texture_rectangle`; pixel indexed & no repeat or MIPmaps or
//   cubemaps
// - `Pvr_Load_Direct`: will load PVR files directly without any additional processing ( if
//   supported)
Texture_Flags :: bit_set[Texture_Flag;u32]
Texture_Flag :: enum u32 {
	Power_Of_Two,
	Mipmaps,
	Texture_Repeats,
	Multiply_Alpha,
	Invert_Y,
	Compress_To_Dxt,
	Dds_Load_Direct,
	Ntsc_Safe_Rgb,
	Co_Cg_Y,
	Texture_Rectangle,
	Pvr_Load_Direct,
	Etc1_Load_Direct,
	Gl_Mipmaps,
	Srgb_Color_Space,
}

// The types of images that may be saved.
//
// - (TGA supports uncompressed RGB / RGBA)
// - (BMP supports uncompressed RGB)
// - (DDS supports DXT1 and DXT5)
// - (PNG supports RGB / RGBA)
Save_Type :: enum i32 {
	Tga,
	Bmp,
	Png,
	Dds,
	Jpg,
	Qoi,
}

// Defines the order of faces in a DDS cubemap.
//
// I recommend that you use the same order in single image cubemap files, so they will be
// interchangeable with DDS cubemaps when using SOIL.
DDS_CUBEMAP_FACE_ORDER :: [6]u8{'E', 'W', 'U', 'D', 'N', 'S'}

// The types of internal fake HDR representations.
//
// - `Rgbe`: RGB * pow( 2.0, A - 128.0 )
// - `Rg_Bdiv_A`: RGB / A
// - `Rg_Bdiv_A2`: RGB / (A*A)
HDR_Type :: enum i32 {
	Rgbe,
	Rg_Bdiv_A,
	Rg_Bdiv_A2,
}

@(default_calling_convention = "c", link_prefix = "SOIL_")
foreign _LIB_ {
	// Loads an image from disk into an OpenGL texture.
	//
	// Inputs:
	// - `filename`: the name of the file to upload as a texture
	// - `force_channels`: `Auto`, `L`, `La`, `Rgb`, `Rgba`,
	// - `reuse_texture_ID`: `true` generate a new texture ID, otherwise reuse the texture ID
	//   (overwriting the old texture)
	// - `flags`: can be any of `Power_Of_Two`, `Mipmaps`, `Texture_Repeats`, `Multiply_Alpha`,
	//   `Invert_Y`, `Compress_To_Dxt`, `Dds_Load_Direct`
	//
	// Returns: `0`-failed, otherwise returns the OpenGL texture handle.
	load_OGL_texture :: proc(
		filename: cstring,
		force_channels: Image_Format,
		reuse_texture_ID: u32,
		flags: Texture_Flags,
	) -> u32 ---

	// Loads 6 images from disk into an OpenGL cubemap texture.
	//
	// Inputs:
	// - `x_pos_file`: the name of the file to upload as the +x cube face
	// - `x_neg_file`: the name of the file to upload as the -x cube face
	// - `y_pos_file`: the name of the file to upload as the +y cube face
	// - `y_neg_file`: the name of the file to upload as the -y cube face
	// - `z_pos_file`: the name of the file to upload as the +z cube face
	// - `z_neg_file`: the name of the file to upload as the -z cube face
	// - `force_channels`: `Auto`, `L`, `La`, `Rgb`, `Rgba`,
	// - `reuse_texture_ID`: `true` generate a new texture ID, otherwise reuse the texture ID
	//   (overwriting the old texture)
	// - `flags`: can be any of `Power_Of_Two`, `Mipmaps`, `Texture_Repeats`, `Multiply_Alpha`,
	//   `Invert_Y`, `Compress_To_Dxt`, `Dds_Load_Direct`
	//
	// Returns: `0` failed, otherwise returns the OpenGL texture handle.
	load_OGL_cubemap :: proc(
		x_pos_file, x_neg_file: cstring,
		y_pos_file, y_neg_file: cstring,
		z_pos_file, z_neg_file: cstring,
		force_channels: Image_Format,
		reuse_texture_ID: u32,
		flags: Texture_Flags,
	) -> u32 ---

	// Loads 1 image from disk and splits it into an OpenGL cubemap texture.
	//
	// Inputs:
	// - `filename`: the name of the file to upload as a texture
	// - `face_order`: the order of the faces in the file, any combination of NSWEUD, for
	//   North, South, Up, etc.
	// - `force_channels`: `Auto`, `L`, `La`, `Rgb`, `Rgba`,
	// - `reuse_texture_ID`: `true` generate a new texture ID, otherwise reuse the texture ID
	//   (overwriting the old texture)
	// - `flags`: can be any of `Power_Of_Two`, `Mipmaps`, `Texture_Repeats`, `Multiply_Alpha`,
	//   `Invert_Y`, `Compress_To_Dxt`, `Dds_Load_Direct`
	//
	// Returns: `0` failed, otherwise returns the OpenGL texture handle.
	load_OGL_single_cubemap :: proc(
		filename: cstring,
		face_order: [6]u8,
		force_channels: Image_Format,
		reuse_texture_ID: u32,
		flags: Texture_Flags,
	) -> u32 ---

	// Loads an HDR image from disk into an OpenGL texture.
	//
	// Inputs:
	// - `filename`: the name of the file to upload as a texture
	// - `fake_HDR_format`: `Hdr_Rgbe`, `Hdr_Rg_Bdiv_A`, `Hdr_Rg_Bdiv_A2`
	// - `reuse_texture_ID`: `true` generate a new texture ID, otherwise reuse the texture ID
	//   (overwriting the old texture)
	// - `flags`: can be any of `Power_Of_Two`, `Mipmaps`, `Texture_Repeats`, `Multiply_Alpha`,
	//   `Invert_Y`, `Compress_To_Dxt`, `Dds_Load_Direct`
	//
	// Returns: `0` failed, otherwise returns the OpenGL texture handle.
	load_OGL_HDR_texture :: proc(
		filename: cstring,
		fake_HDR_format: HDR_Type,
		rescale_to_max: b32,
		reuse_texture_ID: u32,
		flags: Texture_Flags,
	) -> u32 ---

	// Loads an image from RAM into an OpenGL texture.
	//
	// Inputs:
	// - `buffer`: the image data in RAM just as if it were still in a file
	// - `buffer_length`: the size of the buffer in bytes
	// - `force_channels`: `Auto`, `L`, `La`, `Rgb`, `Rgba`,
	// - `reuse_texture_ID`: `true` generate a new texture ID, otherwise reuse the texture ID
	//   (overwriting the old texture)
	// - `flags`: can be any of `Power_Of_Two`, `Mipmaps`, `Texture_Repeats`, `Multiply_Alpha`,
	//   `Invert_Y`, `Compress_To_Dxt`, `Dds_Load_Direct`
	//
	// Returns: `0` failed, otherwise returns the OpenGL texture handle.
	load_OGL_texture_from_memory :: proc(
		buffer: [^]u8,
		buffer_length: i32,
		force_channels: Image_Format,
		reuse_texture_ID: u32,
		flags: Texture_Flags,
	) -> u32 ---

	// Loads 6 images from memory into an OpenGL cubemap texture.
	//
	// Inputs:
	// - `x_pos_buffer`: the image data in RAM to upload as the +x cube face
	// - `x_pos_buffer_length`: the size of the above buffer
	// - `x_neg_buffer`: the image data in RAM to upload as the +x cube face
	// - `x_neg_buffer_length`: the size of the above buffer
	// - `y_pos_buffer`: the image data in RAM to upload as the +x cube face
	// - `y_pos_buffer_length`: the size of the above buffer
	// - `y_neg_buffer`: the image data in RAM to upload as the +x cube face
	// - `y_neg_buffer_length`: the size of the above buffer
	// - `z_pos_buffer`: the image data in RAM to upload as the +x cube face
	// - `z_pos_buffer_length`: the size of the above buffer
	// - `z_neg_buffer`: the image data in RAM to upload as the +x cube face
	// - `z_neg_buffer_length`: the size of the above buffer
	// - `force_channels`: `Auto`, `L`, `La`, `Rgb`, `Rgba`,
	// - `reuse_texture_ID`: `true` generate a new texture ID, otherwise reuse the texture ID
	//   (overwriting the old texture)
	// - `flags`: can be any of `Power_Of_Two`, `Mipmaps`, `Texture_Repeats`, `Multiply_Alpha`,
	//   `Invert_Y`, `Compress_To_Dxt`, `Dds_Load_Direct`
	//
	// Returns: `0` failed, otherwise returns the OpenGL texture handle.
	load_OGL_cubemap_from_memory :: proc(
		x_pos_buffer: [^]u8, x_pos_buffer_length: i32,
		x_neg_buffer: [^]u8, x_neg_buffer_length: i32,
		y_pos_buffer: [^]u8, y_pos_buffer_length: i32,
		y_neg_buffer: [^]u8, y_neg_buffer_length: i32,
		z_pos_buffer: [^]u8, z_pos_buffer_length: i32,
		z_neg_buffer: [^]u8, z_neg_buffer_length: i32,
		force_channels: Image_Format,
		reuse_texture_ID: u32,
		flags: Texture_Flags,
	) -> u32 ---

	// Loads 1 image from RAM and splits it into an OpenGL cubemap texture.
	//
	// Inputs:
	// - `buffer`: the image data in RAM just as if it were still in a file
	// - `buffer_length`: the size of the buffer in bytes
	// - `face_order`: the order of the faces in the file, any combination of `NSWEUD`, for
	//   North, South, Up, etc.
	// - `force_channels`: `Auto`, `L`, `La`, `Rgb`, `Rgba`,
	// - `reuse_texture_ID`: `true` generate a new texture ID, otherwise reuse the texture ID
	//   (overwriting the old texture)
	// - `flags`: can be any of `Power_Of_Two`, `Mipmaps`, `Texture_Repeats`, `Multiply_Alpha`,
	//   `Invert_Y`, `Compress_To_Dxt`, `Dds_Load_Direct`
	//
	// Returns: `0` failed, otherwise returns the OpenGL texture handle.
	load_OGL_single_cubemap_from_memory :: proc(
		buffer: [^]u8,
		buffer_length: i32,
		face_order: [6]u8,
		force_channels: Image_Format,
		reuse_texture_ID: u32,
		flags: Texture_Flags,
	) -> u32 ---

	// Creates a 2D OpenGL texture from raw image data. Note that the raw data is not freed
	// after the upload (so the user can load various versions).
	//
	// Inputs:
	// - `data`: the raw data to be uploaded as an OpenGL texture
	// - `width`: the pointer of the width of the image in pixels (if the texture size change,
	//   width will be overridden with the new width)
	// - `height`: the pointer of the height of the image in pixels (if the texture size
	//   change, height will be overridden with the new height)
	// - `channels`: `Auto`, `L`, `La`, `Rgb`, `Rgba`,
	// - `reuse_texture_ID`: `true` generate a new texture ID, otherwise reuse the texture ID
	//   (overwriting the old texture)
	// - `flags`: can be any of `Power_Of_Two`, `Mipmaps`, `Texture_Repeats`, `Multiply_Alpha`,
	//   `Invert_Y`, `Compress_To_Dxt`, `Dds_Load_Direct`
	//
	// Returns: `0` failed, otherwise returns the OpenGL texture handle.
	create_OGL_texture :: proc(
		data: [^]u8,
		width: ^i32,
		height: ^i32,
		channels: i32,
		reuse_texture_ID: u32,
		flags: Texture_Flags,
	) -> u32 ---

	// Creates an OpenGL cubemap texture by splitting up 1 image into 6 parts.
	//
	// Inputs:
	// - `data`: the raw data to be uploaded as an OpenGL texture
	// - `width`: the width of the image in pixels
	// - `height`: the height of the image in pixels
	// - `channels`: `Auto`, `L`, `La`, `Rgb`, `Rgba`,
	// - `face_order`: the order of the faces in the file, and combination of `NSWEUD`, for
	//   North, South, Up, etc.
	// - `reuse_texture_ID`: `true` generate a new texture ID, otherwise reuse the texture ID
	//   (overwriting the old texture)
	// - `flags`: can be any of `Power_Of_Two`, `Mipmaps`, `Texture_Repeats`, `Multiply_Alpha`,
	//   `Invert_Y`, `Compress_To_Dxt`, `Dds_Load_Direct`
	//
	// Returns: `0` failed, otherwise returns the OpenGL texture handle.
	create_OGL_single_cubemap :: proc(
		data: [^]u8,
		width: i32,
		height: i32,
		channels: i32,
		face_order: [6]u8,
		reuse_texture_ID: u32,
		flags: Texture_Flags,
	) -> u32 ---

	// Captures the OpenGL window (RGB) and saves it to disk.
	//
	// Returns: `0` if it failed, otherwise returns `1`
	save_screenshot :: proc(
		filename: cstring,
		image_type: Save_Type,
		x: i32,
		y: i32,
		width: i32,
		height: i32,
	) -> i32 ---

	// Loads an image from disk into an array of unsigned chars
	//
	// Note that `channels` return the original channel count of the image.  If
	// `force_channels` was other than `Auto`, the resulting image has `force_channels`, but
	// `channels` may be different (if the original image had a different channel count).
	//
	// Returns: A pointer to the loaded image data if successful, otherwise `nil` if it failed.
	load_image :: proc(
		filename: cstring,
		width: ^i32,
		height: ^i32,
		channels: ^i32,
		force_channels: Image_Format,
	) -> [^]u8 ---

	// Loads an image from memory into an array of unsigned chars.
	//
	// Note that `channels` return the original channel count of the image.  If
	// `force_channels` was other than `Auto`, the resulting image has `force_channels`, but
	// `channels` may be different (if the original image had a different channel count).
	//
	// Returns: A pointer to the loaded image data if successful, otherwise `nil` if it failed.
	load_image_from_memory :: proc(
		buffer: [^]u8,
		buffer_length: i32,
		width: ^i32,
		height: ^i32,
		channels: ^i32,
		force_channels: Image_Format,
	) -> [^]u8 ---

	// Saves an image from an array of unsigned chars (RGBA) to disk
	//
	// Inputs:
	// - `quality:` parameter only used for `Save_Type.Jpg` files, values accepted between `0`
	//   and `100`.
	//
	// Returns: `0` if failed, otherwise returns `1`.
	save_image_quality :: proc(
		filename: cstring,
		image_type: Save_Type,
		width: i32,
		height: i32,
		channels: i32,
		data: [^]u8,
		quality: i32,
	) -> i32 ---

	// Saves an image from an array of unsigned chars (RGBA) to disk
	//
	// Returns: `0` if failed, otherwise returns `1`.
	save_image :: proc(
		filename: cstring,
		image_type: Save_Type,
		width: i32,
		height: i32,
		channels: i32,
		data: [^]u8,
	) -> i32 ---

	// Saves an image from an array of unsigned chars (RGBA) to a memory buffer in the target
	// format. Free the buffer with `free_image_data`.
	//
	// Inputs:
	// - `quality:` parameter only used for `Save_Type.Jpg` files, values accepted between `0`
	//   and `100`.
	// - `imageSize`: returns the byte count of the image.
	//
	// Returns: A pointer to the loaded image data if successful, otherwise `nil` if it failed.
	write_image_to_memory_quality :: proc(
		image_type: Save_Type,
		width: i32,
		height: i32,
		channels: i32,
		data: [^]u8,
		quality: i32,
		imageSize: ^i32,
	) -> [^]u8 ---

	// Saves an image from an array of unsigned chars (RGBA) to a memory buffer in the target
	// format. Free the buffer with `free_image_data`.
	//
	// Inputs:
	// - `imageSize`: returns the byte count of the image.
	//
	// Returns: A pointer to the loaded image data if successful, otherwise `nil` if it failed.
	write_image_to_memory :: proc(
		image_type: Save_Type,
		width: i32,
		height: i32,
		channels: i32,
		data: [^]u8,
		imageSize: ^i32,
	) -> [^]u8 ---

	// Frees the image data.
	free_image_data :: proc(
		img_data: [^]u8,
	) ---

	// This procedure return a pointer to a string describing the last thing that happened
	// inside SOIL. It can be used to determine why an image failed to load.
	last_result :: proc() -> cstring ---

	// Returns  the address of the GL function proc, or `nil` if the function is not found.
	GL_GetProcAddress :: proc(
		proc_name: cstring,
	) -> rawptr ---

	// Return `1` if an OpenGL extension is supported for the current context, `0` otherwise.
	GL_ExtensionSupported :: proc(
		extension: cstring,
	) -> i32 ---

	// Loads the DDS texture directly to the GPU memory (if supported).
	direct_load_DDS :: proc(
		filename: cstring,
		reuse_texture_ID: u32,
		flags: Texture_Flags,
		loading_as_cubemap: i32,
	) -> u32 ---

	// Loads the DDS texture directly to the GPU memory (if supported).
	direct_load_DDS_from_memory :: proc(
		buffer: [^]u8,
		buffer_length: i32,
		reuse_texture_ID: u32,
		flags: Texture_Flags,
		loading_as_cubemap: i32,
	) -> u32 ---

	// Loads the PVR texture directly to the GPU memory (if supported).
	direct_load_PVR :: proc(
		filename: cstring,
		reuse_texture_ID: u32,
		flags: Texture_Flags,
		loading_as_cubemap: i32,
	) -> u32 ---

	// Loads the PVR texture directly to the GPU memory (if supported).
	direct_load_PVR_from_memory :: proc(
		buffer: [^]u8,
		buffer_length: i32,
		reuse_texture_ID: u32,
		flags: Texture_Flags,
		loading_as_cubemap: i32,
	) -> u32 ---

	// Loads the ETC1 texture directly to the GPU memory (if supported).
	direct_load_ETC1 :: proc(
		filename: cstring,
		reuse_texture_ID: u32,
		flags: Texture_Flags,
	) -> u32 ---

	// Loads the ETC1 texture directly to the GPU memory (if supported).
	direct_load_ETC1_from_memory :: proc(
		buffer: [^]u8,
		buffer_length: i32,
		reuse_texture_ID: u32,
		flags: Texture_Flags,
	) -> u32 ---
}
