module LibSkia

using CEnum

# TODO Use artifacts

const LibSkiaSharp = "libSkiaSharp.dll"


const intptr_t = Clonglong

mutable struct sk_refcnt_t end

mutable struct sk_nvrefcnt_t end

mutable struct sk_flattenable_t end

const sk_color_t = UInt32

const sk_pmcolor_t = UInt32

struct sk_color4f_t
    fR::Cfloat
    fG::Cfloat
    fB::Cfloat
    fA::Cfloat
end

@cenum sk_colortype_t::UInt32 begin
    UNKNOWN_SK_COLORTYPE = 0
    ALPHA_8_SK_COLORTYPE = 1
    RGB_565_SK_COLORTYPE = 2
    ARGB_4444_SK_COLORTYPE = 3
    RGBA_8888_SK_COLORTYPE = 4
    RGB_888X_SK_COLORTYPE = 5
    BGRA_8888_SK_COLORTYPE = 6
    RGBA_1010102_SK_COLORTYPE = 7
    BGRA_1010102_SK_COLORTYPE = 8
    RGB_101010X_SK_COLORTYPE = 9
    BGR_101010X_SK_COLORTYPE = 10
    BGR_101010X_XR_SK_COLORTYPE = 11
    RGBA_10X6_SK_COLORTYPE = 12
    GRAY_8_SK_COLORTYPE = 13
    RGBA_F16_NORM_SK_COLORTYPE = 14
    RGBA_F16_SK_COLORTYPE = 15
    RGBA_F32_SK_COLORTYPE = 16
    R8G8_UNORM_SK_COLORTYPE = 17
    A16_FLOAT_SK_COLORTYPE = 18
    R16G16_FLOAT_SK_COLORTYPE = 19
    A16_UNORM_SK_COLORTYPE = 20
    R16G16_UNORM_SK_COLORTYPE = 21
    R16G16B16A16_UNORM_SK_COLORTYPE = 22
    SRGBA_8888_SK_COLORTYPE = 23
    R8_UNORM_SK_COLORTYPE = 24
end

@cenum sk_alphatype_t::UInt32 begin
    UNKNOWN_SK_ALPHATYPE = 0
    OPAQUE_SK_ALPHATYPE = 1
    PREMUL_SK_ALPHATYPE = 2
    UNPREMUL_SK_ALPHATYPE = 3
end

@cenum sk_pixelgeometry_t::UInt32 begin
    UNKNOWN_SK_PIXELGEOMETRY = 0
    RGB_H_SK_PIXELGEOMETRY = 1
    BGR_H_SK_PIXELGEOMETRY = 2
    RGB_V_SK_PIXELGEOMETRY = 3
    BGR_V_SK_PIXELGEOMETRY = 4
end

@cenum sk_surfaceprops_flags_t::UInt32 begin
    NONE_SK_SURFACE_PROPS_FLAGS = 0
    USE_DEVICE_INDEPENDENT_FONTS_SK_SURFACE_PROPS_FLAGS = 1
end

mutable struct sk_surfaceprops_t end

struct sk_point_t
    x::Cfloat
    y::Cfloat
end

const sk_vector_t = sk_point_t

struct sk_irect_t
    left::Int32
    top::Int32
    right::Int32
    bottom::Int32
end

struct sk_rect_t
    left::Cfloat
    top::Cfloat
    right::Cfloat
    bottom::Cfloat
end

struct sk_matrix_t
    scaleX::Cfloat
    skewX::Cfloat
    transX::Cfloat
    skewY::Cfloat
    scaleY::Cfloat
    transY::Cfloat
    persp0::Cfloat
    persp1::Cfloat
    persp2::Cfloat
end

struct sk_matrix44_t
    m00::Cfloat
    m01::Cfloat
    m02::Cfloat
    m03::Cfloat
    m10::Cfloat
    m11::Cfloat
    m12::Cfloat
    m13::Cfloat
    m20::Cfloat
    m21::Cfloat
    m22::Cfloat
    m23::Cfloat
    m30::Cfloat
    m31::Cfloat
    m32::Cfloat
    m33::Cfloat
end

mutable struct sk_canvas_t end

mutable struct sk_nodraw_canvas_t end

mutable struct sk_nway_canvas_t end

mutable struct sk_overdraw_canvas_t end

mutable struct sk_data_t end

mutable struct sk_drawable_t end

mutable struct sk_image_t end

mutable struct sk_maskfilter_t end

mutable struct sk_paint_t end

mutable struct sk_font_t end

mutable struct sk_path_t end

mutable struct sk_picture_t end

mutable struct sk_picture_recorder_t end

mutable struct sk_bbh_factory_t end

mutable struct sk_rtree_factory_t end

mutable struct sk_shader_t end

mutable struct sk_surface_t end

mutable struct sk_region_t end

mutable struct sk_region_iterator_t end

mutable struct sk_region_cliperator_t end

mutable struct sk_region_spanerator_t end

@cenum sk_blendmode_t::UInt32 begin
    CLEAR_SK_BLENDMODE = 0
    SRC_SK_BLENDMODE = 1
    DST_SK_BLENDMODE = 2
    SRCOVER_SK_BLENDMODE = 3
    DSTOVER_SK_BLENDMODE = 4
    SRCIN_SK_BLENDMODE = 5
    DSTIN_SK_BLENDMODE = 6
    SRCOUT_SK_BLENDMODE = 7
    DSTOUT_SK_BLENDMODE = 8
    SRCATOP_SK_BLENDMODE = 9
    DSTATOP_SK_BLENDMODE = 10
    XOR_SK_BLENDMODE = 11
    PLUS_SK_BLENDMODE = 12
    MODULATE_SK_BLENDMODE = 13
    SCREEN_SK_BLENDMODE = 14
    OVERLAY_SK_BLENDMODE = 15
    DARKEN_SK_BLENDMODE = 16
    LIGHTEN_SK_BLENDMODE = 17
    COLORDODGE_SK_BLENDMODE = 18
    COLORBURN_SK_BLENDMODE = 19
    HARDLIGHT_SK_BLENDMODE = 20
    SOFTLIGHT_SK_BLENDMODE = 21
    DIFFERENCE_SK_BLENDMODE = 22
    EXCLUSION_SK_BLENDMODE = 23
    MULTIPLY_SK_BLENDMODE = 24
    HUE_SK_BLENDMODE = 25
    SATURATION_SK_BLENDMODE = 26
    COLOR_SK_BLENDMODE = 27
    LUMINOSITY_SK_BLENDMODE = 28
end

struct sk_point3_t
    x::Cfloat
    y::Cfloat
    z::Cfloat
end

struct sk_ipoint_t
    x::Int32
    y::Int32
end

struct sk_size_t
    w::Cfloat
    h::Cfloat
end

struct sk_isize_t
    w::Int32
    h::Int32
end

struct sk_fontmetrics_t
    fFlags::UInt32
    fTop::Cfloat
    fAscent::Cfloat
    fDescent::Cfloat
    fBottom::Cfloat
    fLeading::Cfloat
    fAvgCharWidth::Cfloat
    fMaxCharWidth::Cfloat
    fXMin::Cfloat
    fXMax::Cfloat
    fXHeight::Cfloat
    fCapHeight::Cfloat
    fUnderlineThickness::Cfloat
    fUnderlinePosition::Cfloat
    fStrikeoutThickness::Cfloat
    fStrikeoutPosition::Cfloat
end

mutable struct sk_string_t end

mutable struct sk_bitmap_t end

mutable struct sk_pixmap_t end

mutable struct sk_colorfilter_t end

mutable struct sk_imagefilter_t end

mutable struct sk_blender_t end

mutable struct sk_typeface_t end

const sk_font_table_tag_t = UInt32

mutable struct sk_fontmgr_t end

mutable struct sk_fontstyle_t end

mutable struct sk_fontstyleset_t end

mutable struct sk_codec_t end

mutable struct sk_colorspace_t end

mutable struct sk_stream_t end

mutable struct sk_stream_filestream_t end

mutable struct sk_stream_asset_t end

mutable struct sk_stream_memorystream_t end

mutable struct sk_stream_streamrewindable_t end

mutable struct sk_wstream_t end

mutable struct sk_wstream_filestream_t end

mutable struct sk_wstream_dynamicmemorystream_t end

mutable struct sk_document_t end

@cenum sk_point_mode_t::UInt32 begin
    POINTS_SK_POINT_MODE = 0
    LINES_SK_POINT_MODE = 1
    POLYGON_SK_POINT_MODE = 2
end

@cenum sk_text_align_t::UInt32 begin
    LEFT_SK_TEXT_ALIGN = 0
    CENTER_SK_TEXT_ALIGN = 1
    RIGHT_SK_TEXT_ALIGN = 2
end

@cenum sk_text_encoding_t::UInt32 begin
    UTF8_SK_TEXT_ENCODING = 0
    UTF16_SK_TEXT_ENCODING = 1
    UTF32_SK_TEXT_ENCODING = 2
    GLYPH_ID_SK_TEXT_ENCODING = 3
end

@cenum sk_path_filltype_t::UInt32 begin
    WINDING_SK_PATH_FILLTYPE = 0
    EVENODD_SK_PATH_FILLTYPE = 1
    INVERSE_WINDING_SK_PATH_FILLTYPE = 2
    INVERSE_EVENODD_SK_PATH_FILLTYPE = 3
end

@cenum sk_font_style_slant_t::UInt32 begin
    UPRIGHT_SK_FONT_STYLE_SLANT = 0
    ITALIC_SK_FONT_STYLE_SLANT = 1
    OBLIQUE_SK_FONT_STYLE_SLANT = 2
end

@cenum sk_color_channel_t::UInt32 begin
    R_SK_COLOR_CHANNEL = 0
    G_SK_COLOR_CHANNEL = 1
    B_SK_COLOR_CHANNEL = 2
    A_SK_COLOR_CHANNEL = 3
end

@cenum sk_region_op_t::UInt32 begin
    DIFFERENCE_SK_REGION_OP = 0
    INTERSECT_SK_REGION_OP = 1
    UNION_SK_REGION_OP = 2
    XOR_SK_REGION_OP = 3
    REVERSE_DIFFERENCE_SK_REGION_OP = 4
    REPLACE_SK_REGION_OP = 5
end

@cenum sk_clipop_t::UInt32 begin
    DIFFERENCE_SK_CLIPOP = 0
    INTERSECT_SK_CLIPOP = 1
end

@cenum sk_encoded_image_format_t::UInt32 begin
    BMP_SK_ENCODED_FORMAT = 0
    GIF_SK_ENCODED_FORMAT = 1
    ICO_SK_ENCODED_FORMAT = 2
    JPEG_SK_ENCODED_FORMAT = 3
    PNG_SK_ENCODED_FORMAT = 4
    WBMP_SK_ENCODED_FORMAT = 5
    WEBP_SK_ENCODED_FORMAT = 6
    PKM_SK_ENCODED_FORMAT = 7
    KTX_SK_ENCODED_FORMAT = 8
    ASTC_SK_ENCODED_FORMAT = 9
    DNG_SK_ENCODED_FORMAT = 10
    HEIF_SK_ENCODED_FORMAT = 11
    AVIF_SK_ENCODED_FORMAT = 12
    JPEGXL_SK_ENCODED_FORMAT = 13
end

@cenum sk_encodedorigin_t::UInt32 begin
    TOP_LEFT_SK_ENCODED_ORIGIN = 1
    TOP_RIGHT_SK_ENCODED_ORIGIN = 2
    BOTTOM_RIGHT_SK_ENCODED_ORIGIN = 3
    BOTTOM_LEFT_SK_ENCODED_ORIGIN = 4
    LEFT_TOP_SK_ENCODED_ORIGIN = 5
    RIGHT_TOP_SK_ENCODED_ORIGIN = 6
    RIGHT_BOTTOM_SK_ENCODED_ORIGIN = 7
    LEFT_BOTTOM_SK_ENCODED_ORIGIN = 8
    DEFAULT_SK_ENCODED_ORIGIN = 1
end

@cenum sk_codec_result_t::UInt32 begin
    SUCCESS_SK_CODEC_RESULT = 0
    INCOMPLETE_INPUT_SK_CODEC_RESULT = 1
    ERROR_IN_INPUT_SK_CODEC_RESULT = 2
    INVALID_CONVERSION_SK_CODEC_RESULT = 3
    INVALID_SCALE_SK_CODEC_RESULT = 4
    INVALID_PARAMETERS_SK_CODEC_RESULT = 5
    INVALID_INPUT_SK_CODEC_RESULT = 6
    COULD_NOT_REWIND_SK_CODEC_RESULT = 7
    INTERNAL_ERROR_SK_CODEC_RESULT = 8
    UNIMPLEMENTED_SK_CODEC_RESULT = 9
end

@cenum sk_codec_zero_initialized_t::UInt32 begin
    YES_SK_CODEC_ZERO_INITIALIZED = 0
    NO_SK_CODEC_ZERO_INITIALIZED = 1
end

struct sk_codec_options_t
    fZeroInitialized::sk_codec_zero_initialized_t
    fSubset::Ptr{sk_irect_t}
    fFrameIndex::Cint
    fPriorFrame::Cint
end

@cenum sk_codec_scanline_order_t::UInt32 begin
    TOP_DOWN_SK_CODEC_SCANLINE_ORDER = 0
    BOTTOM_UP_SK_CODEC_SCANLINE_ORDER = 1
end

@cenum sk_path_verb_t::UInt32 begin
    MOVE_SK_PATH_VERB = 0
    LINE_SK_PATH_VERB = 1
    QUAD_SK_PATH_VERB = 2
    CONIC_SK_PATH_VERB = 3
    CUBIC_SK_PATH_VERB = 4
    CLOSE_SK_PATH_VERB = 5
    DONE_SK_PATH_VERB = 6
end

mutable struct sk_path_iterator_t end

mutable struct sk_path_rawiterator_t end

@cenum sk_path_add_mode_t::UInt32 begin
    APPEND_SK_PATH_ADD_MODE = 0
    EXTEND_SK_PATH_ADD_MODE = 1
end

@cenum sk_path_segment_mask_t::UInt32 begin
    LINE_SK_PATH_SEGMENT_MASK = 1
    QUAD_SK_PATH_SEGMENT_MASK = 2
    CONIC_SK_PATH_SEGMENT_MASK = 4
    CUBIC_SK_PATH_SEGMENT_MASK = 8
end

@cenum sk_path_effect_1d_style_t::UInt32 begin
    TRANSLATE_SK_PATH_EFFECT_1D_STYLE = 0
    ROTATE_SK_PATH_EFFECT_1D_STYLE = 1
    MORPH_SK_PATH_EFFECT_1D_STYLE = 2
end

@cenum sk_path_effect_trim_mode_t::UInt32 begin
    NORMAL_SK_PATH_EFFECT_TRIM_MODE = 0
    INVERTED_SK_PATH_EFFECT_TRIM_MODE = 1
end

mutable struct sk_path_effect_t end

@cenum sk_stroke_cap_t::UInt32 begin
    BUTT_SK_STROKE_CAP = 0
    ROUND_SK_STROKE_CAP = 1
    SQUARE_SK_STROKE_CAP = 2
end

@cenum sk_stroke_join_t::UInt32 begin
    MITER_SK_STROKE_JOIN = 0
    ROUND_SK_STROKE_JOIN = 1
    BEVEL_SK_STROKE_JOIN = 2
end

@cenum sk_shader_tilemode_t::UInt32 begin
    CLAMP_SK_SHADER_TILEMODE = 0
    REPEAT_SK_SHADER_TILEMODE = 1
    MIRROR_SK_SHADER_TILEMODE = 2
    DECAL_SK_SHADER_TILEMODE = 3
end

@cenum sk_blurstyle_t::UInt32 begin
    NORMAL_SK_BLUR_STYLE = 0
    SOLID_SK_BLUR_STYLE = 1
    OUTER_SK_BLUR_STYLE = 2
    INNER_SK_BLUR_STYLE = 3
end

@cenum sk_path_direction_t::UInt32 begin
    CW_SK_PATH_DIRECTION = 0
    CCW_SK_PATH_DIRECTION = 1
end

@cenum sk_path_arc_size_t::UInt32 begin
    SMALL_SK_PATH_ARC_SIZE = 0
    LARGE_SK_PATH_ARC_SIZE = 1
end

@cenum sk_paint_style_t::UInt32 begin
    FILL_SK_PAINT_STYLE = 0
    STROKE_SK_PAINT_STYLE = 1
    STROKE_AND_FILL_SK_PAINT_STYLE = 2
end

@cenum sk_font_hinting_t::UInt32 begin
    NONE_SK_FONT_HINTING = 0
    SLIGHT_SK_FONT_HINTING = 1
    NORMAL_SK_FONT_HINTING = 2
    FULL_SK_FONT_HINTING = 3
end

@cenum sk_font_edging_t::UInt32 begin
    ALIAS_SK_FONT_EDGING = 0
    ANTIALIAS_SK_FONT_EDGING = 1
    SUBPIXEL_ANTIALIAS_SK_FONT_EDGING = 2
end

mutable struct sk_pixelref_factory_t end

@cenum gr_surfaceorigin_t::UInt32 begin
    TOP_LEFT_GR_SURFACE_ORIGIN = 0
    BOTTOM_LEFT_GR_SURFACE_ORIGIN = 1
end

struct gr_context_options_t
    fAvoidStencilBuffers::Bool
    fRuntimeProgramCacheSize::Cint
    fGlyphCacheTextureMaximumBytes::Csize_t
    fAllowPathMaskCaching::Bool
    fDoManualMipmapping::Bool
    fBufferMapThreshold::Cint
end

const gr_backendobject_t = intptr_t

mutable struct gr_backendrendertarget_t end

mutable struct gr_backendtexture_t end

mutable struct gr_direct_context_t end

mutable struct gr_recording_context_t end

@cenum gr_backend_t::UInt32 begin
    OPENGL_GR_BACKEND = 0
    VULKAN_GR_BACKEND = 1
    METAL_GR_BACKEND = 2
    DIRECT3D_GR_BACKEND = 3
    UNSUPPORTED_GR_BACKEND = 5
end

const gr_backendcontext_t = intptr_t

mutable struct gr_glinterface_t end

# typedef void ( * gr_gl_func_ptr ) ( void )
const gr_gl_func_ptr = Ptr{Cvoid}

# typedef gr_gl_func_ptr ( * gr_gl_get_proc ) ( void * ctx , const char * name )
const gr_gl_get_proc = Ptr{Cvoid}

struct gr_gl_textureinfo_t
    fTarget::Cuint
    fID::Cuint
    fFormat::Cuint
    fProtected::Bool
end

struct gr_gl_framebufferinfo_t
    fFBOID::Cuint
    fFormat::Cuint
    fProtected::Bool
end

mutable struct vk_instance_t end

mutable struct gr_vkinterface_t end

mutable struct vk_physical_device_t end

mutable struct vk_physical_device_features_t end

mutable struct vk_physical_device_features_2_t end

mutable struct vk_device_t end

mutable struct vk_queue_t end

mutable struct gr_vk_extensions_t end

mutable struct gr_vk_memory_allocator_t end

# typedef VKAPI_ATTR void ( VKAPI_CALL * gr_vk_func_ptr
const gr_vk_func_ptr = Ptr{Cvoid}

# typedef gr_vk_func_ptr ( * gr_vk_get_proc ) ( void * ctx , const char * name , vk_instance_t * instance , vk_device_t * device )
const gr_vk_get_proc = Ptr{Cvoid}

struct gr_vk_backendcontext_t
    fInstance::Ptr{vk_instance_t}
    fPhysicalDevice::Ptr{vk_physical_device_t}
    fDevice::Ptr{vk_device_t}
    fQueue::Ptr{vk_queue_t}
    fGraphicsQueueIndex::UInt32
    fMinAPIVersion::UInt32
    fInstanceVersion::UInt32
    fMaxAPIVersion::UInt32
    fExtensions::UInt32
    fVkExtensions::Ptr{gr_vk_extensions_t}
    fFeatures::UInt32
    fDeviceFeatures::Ptr{vk_physical_device_features_t}
    fDeviceFeatures2::Ptr{vk_physical_device_features_2_t}
    fMemoryAllocator::Ptr{gr_vk_memory_allocator_t}
    fGetProc::gr_vk_get_proc
    fGetProcUserData::Ptr{Cvoid}
    fOwnsInstanceAndDevice::Bool
    fProtectedContext::Bool
end

const gr_vk_backendmemory_t = intptr_t

struct gr_vk_alloc_t
    fMemory::UInt64
    fOffset::UInt64
    fSize::UInt64
    fFlags::UInt32
    fBackendMemory::gr_vk_backendmemory_t
    _private_fUsesSystemHeap::Bool
end

struct gr_vk_ycbcrconversioninfo_t
    fFormat::UInt32
    fExternalFormat::UInt64
    fYcbcrModel::UInt32
    fYcbcrRange::UInt32
    fXChromaOffset::UInt32
    fYChromaOffset::UInt32
    fChromaFilter::UInt32
    fForceExplicitReconstruction::UInt32
    fFormatFeatures::UInt32
end

struct gr_vk_imageinfo_t
    fImage::UInt64
    fAlloc::gr_vk_alloc_t
    fImageTiling::UInt32
    fImageLayout::UInt32
    fFormat::UInt32
    fImageUsageFlags::UInt32
    fSampleCount::UInt32
    fLevelCount::UInt32
    fCurrentQueueFamily::UInt32
    fProtected::Bool
    fYcbcrConversionInfo::gr_vk_ycbcrconversioninfo_t
    fSharingMode::UInt32
end

struct gr_mtl_textureinfo_t
    fTexture::Ptr{Cvoid}
end

@cenum sk_pathop_t::UInt32 begin
    DIFFERENCE_SK_PATHOP = 0
    INTERSECT_SK_PATHOP = 1
    UNION_SK_PATHOP = 2
    XOR_SK_PATHOP = 3
    REVERSE_DIFFERENCE_SK_PATHOP = 4
end

mutable struct sk_opbuilder_t end

@cenum sk_lattice_recttype_t::UInt32 begin
    DEFAULT_SK_LATTICE_RECT_TYPE = 0
    TRANSPARENT_SK_LATTICE_RECT_TYPE = 1
    FIXED_COLOR_SK_LATTICE_RECT_TYPE = 2
end

struct sk_lattice_t
    fXDivs::Ptr{Cint}
    fYDivs::Ptr{Cint}
    fRectTypes::Ptr{sk_lattice_recttype_t}
    fXCount::Cint
    fYCount::Cint
    fBounds::Ptr{sk_irect_t}
    fColors::Ptr{sk_color_t}
end

mutable struct sk_pathmeasure_t end

@cenum sk_pathmeasure_matrixflags_t::UInt32 begin
    GET_POSITION_SK_PATHMEASURE_MATRIXFLAGS = 1
    GET_TANGENT_SK_PATHMEASURE_MATRIXFLAGS = 2
    GET_POS_AND_TAN_SK_PATHMEASURE_MATRIXFLAGS = 3
end

# typedef void ( * sk_bitmap_release_proc ) ( void * addr , void * context )
const sk_bitmap_release_proc = Ptr{Cvoid}

# typedef void ( * sk_data_release_proc ) ( const void * ptr , void * context )
const sk_data_release_proc = Ptr{Cvoid}

# typedef void ( * sk_image_raster_release_proc ) ( const void * addr , void * context )
const sk_image_raster_release_proc = Ptr{Cvoid}

# typedef void ( * sk_image_texture_release_proc ) ( void * context )
const sk_image_texture_release_proc = Ptr{Cvoid}

# typedef void ( * sk_surface_raster_release_proc ) ( void * addr , void * context )
const sk_surface_raster_release_proc = Ptr{Cvoid}

# typedef void ( * sk_glyph_path_proc ) ( const sk_path_t * pathOrNull , const sk_matrix_t * matrix , void * context )
const sk_glyph_path_proc = Ptr{Cvoid}

@cenum sk_image_caching_hint_t::UInt32 begin
    ALLOW_SK_IMAGE_CACHING_HINT = 0
    DISALLOW_SK_IMAGE_CACHING_HINT = 1
end

@cenum sk_bitmap_allocflags_t::UInt32 begin
    NONE_SK_BITMAP_ALLOC_FLAGS = 0
    ZERO_PIXELS_SK_BITMAP_ALLOC_FLAGS = 1
end

struct sk_document_pdf_datetime_t
    fTimeZoneMinutes::Int16
    fYear::UInt16
    fMonth::UInt8
    fDayOfWeek::UInt8
    fDay::UInt8
    fHour::UInt8
    fMinute::UInt8
    fSecond::UInt8
end

struct sk_document_pdf_metadata_t
    fTitle::Ptr{sk_string_t}
    fAuthor::Ptr{sk_string_t}
    fSubject::Ptr{sk_string_t}
    fKeywords::Ptr{sk_string_t}
    fCreator::Ptr{sk_string_t}
    fProducer::Ptr{sk_string_t}
    fCreation::Ptr{sk_document_pdf_datetime_t}
    fModified::Ptr{sk_document_pdf_datetime_t}
    fRasterDPI::Cfloat
    fPDFA::Bool
    fEncodingQuality::Cint
end

struct sk_imageinfo_t
    colorspace::Ptr{sk_colorspace_t}
    width::Int32
    height::Int32
    colorType::sk_colortype_t
    alphaType::sk_alphatype_t
end

@cenum sk_codecanimation_disposalmethod_t::UInt32 begin
    KEEP_SK_CODEC_ANIMATION_DISPOSAL_METHOD = 1
    RESTORE_BG_COLOR_SK_CODEC_ANIMATION_DISPOSAL_METHOD = 2
    RESTORE_PREVIOUS_SK_CODEC_ANIMATION_DISPOSAL_METHOD = 3
end

@cenum sk_codecanimation_blend_t::UInt32 begin
    SRC_OVER_SK_CODEC_ANIMATION_BLEND = 0
    SRC_SK_CODEC_ANIMATION_BLEND = 1
end

struct sk_codec_frameinfo_t
    fRequiredFrame::Cint
    fDuration::Cint
    fFullyReceived::Bool
    fAlphaType::sk_alphatype_t
    fHasAlphaWithinBounds::Bool
    fDisposalMethod::sk_codecanimation_disposalmethod_t
    fBlend::sk_codecanimation_blend_t
    fFrameRect::sk_irect_t
end

mutable struct sk_svgcanvas_t end

@cenum sk_vertices_vertex_mode_t::UInt32 begin
    TRIANGLES_SK_VERTICES_VERTEX_MODE = 0
    TRIANGLE_STRIP_SK_VERTICES_VERTEX_MODE = 1
    TRIANGLE_FAN_SK_VERTICES_VERTEX_MODE = 2
end

mutable struct sk_vertices_t end

struct sk_colorspace_transfer_fn_t
    fG::Cfloat
    fA::Cfloat
    fB::Cfloat
    fC::Cfloat
    fD::Cfloat
    fE::Cfloat
    fF::Cfloat
end

struct sk_colorspace_primaries_t
    fRX::Cfloat
    fRY::Cfloat
    fGX::Cfloat
    fGY::Cfloat
    fBX::Cfloat
    fBY::Cfloat
    fWX::Cfloat
    fWY::Cfloat
end

struct sk_colorspace_xyz_t
    fM00::Cfloat
    fM01::Cfloat
    fM02::Cfloat
    fM10::Cfloat
    fM11::Cfloat
    fM12::Cfloat
    fM20::Cfloat
    fM21::Cfloat
    fM22::Cfloat
end

mutable struct sk_colorspace_icc_profile_t end

@cenum sk_highcontrastconfig_invertstyle_t::UInt32 begin
    NO_INVERT_SK_HIGH_CONTRAST_CONFIG_INVERT_STYLE = 0
    INVERT_BRIGHTNESS_SK_HIGH_CONTRAST_CONFIG_INVERT_STYLE = 1
    INVERT_LIGHTNESS_SK_HIGH_CONTRAST_CONFIG_INVERT_STYLE = 2
end

struct sk_highcontrastconfig_t
    fGrayscale::Bool
    fInvertStyle::sk_highcontrastconfig_invertstyle_t
    fContrast::Cfloat
end

@cenum sk_pngencoder_filterflags_t::UInt32 begin
    ZERO_SK_PNGENCODER_FILTER_FLAGS = 0
    NONE_SK_PNGENCODER_FILTER_FLAGS = 8
    SUB_SK_PNGENCODER_FILTER_FLAGS = 16
    UP_SK_PNGENCODER_FILTER_FLAGS = 32
    AVG_SK_PNGENCODER_FILTER_FLAGS = 64
    PAETH_SK_PNGENCODER_FILTER_FLAGS = 128
    ALL_SK_PNGENCODER_FILTER_FLAGS = 248
end

struct sk_pngencoder_options_t
    fFilterFlags::sk_pngencoder_filterflags_t
    fZLibLevel::Cint
    fComments::Ptr{Cvoid}
    fICCProfile::Ptr{sk_colorspace_icc_profile_t}
    fICCProfileDescription::Ptr{Cchar}
end

@cenum sk_jpegencoder_downsample_t::UInt32 begin
    DOWNSAMPLE_420_SK_JPEGENCODER_DOWNSAMPLE = 0
    DOWNSAMPLE_422_SK_JPEGENCODER_DOWNSAMPLE = 1
    DOWNSAMPLE_444_SK_JPEGENCODER_DOWNSAMPLE = 2
end

@cenum sk_jpegencoder_alphaoption_t::UInt32 begin
    IGNORE_SK_JPEGENCODER_ALPHA_OPTION = 0
    BLEND_ON_BLACK_SK_JPEGENCODER_ALPHA_OPTION = 1
end

struct sk_jpegencoder_options_t
    fQuality::Cint
    fDownsample::sk_jpegencoder_downsample_t
    fAlphaOption::sk_jpegencoder_alphaoption_t
    xmpMetadata::Ptr{sk_data_t}
    fICCProfile::Ptr{sk_colorspace_icc_profile_t}
    fICCProfileDescription::Ptr{Cchar}
end

@cenum sk_webpencoder_compression_t::UInt32 begin
    LOSSY_SK_WEBPENCODER_COMPTRESSION = 0
    LOSSLESS_SK_WEBPENCODER_COMPTRESSION = 1
end

struct sk_webpencoder_options_t
    fCompression::sk_webpencoder_compression_t
    fQuality::Cfloat
    fICCProfile::Ptr{sk_colorspace_icc_profile_t}
    fICCProfileDescription::Ptr{Cchar}
end

mutable struct sk_rrect_t end

@cenum sk_rrect_type_t::UInt32 begin
    EMPTY_SK_RRECT_TYPE = 0
    RECT_SK_RRECT_TYPE = 1
    OVAL_SK_RRECT_TYPE = 2
    SIMPLE_SK_RRECT_TYPE = 3
    NINE_PATCH_SK_RRECT_TYPE = 4
    COMPLEX_SK_RRECT_TYPE = 5
end

@cenum sk_rrect_corner_t::UInt32 begin
    UPPER_LEFT_SK_RRECT_CORNER = 0
    UPPER_RIGHT_SK_RRECT_CORNER = 1
    LOWER_RIGHT_SK_RRECT_CORNER = 2
    LOWER_LEFT_SK_RRECT_CORNER = 3
end

mutable struct sk_textblob_t end

mutable struct sk_textblob_builder_t end

struct sk_textblob_builder_runbuffer_t
    glyphs::Ptr{Cvoid}
    pos::Ptr{Cvoid}
    utf8text::Ptr{Cvoid}
    clusters::Ptr{Cvoid}
end

struct sk_rsxform_t
    fSCos::Cfloat
    fSSin::Cfloat
    fTX::Cfloat
    fTY::Cfloat
end

mutable struct sk_tracememorydump_t end

mutable struct sk_runtimeeffect_t end

@cenum sk_runtimeeffect_uniform_type_t::UInt32 begin
    FLOAT_SK_RUNTIMEEFFECT_UNIFORM_TYPE = 0
    FLOAT2_SK_RUNTIMEEFFECT_UNIFORM_TYPE = 1
    FLOAT3_SK_RUNTIMEEFFECT_UNIFORM_TYPE = 2
    FLOAT4_SK_RUNTIMEEFFECT_UNIFORM_TYPE = 3
    FLOAT2X2_SK_RUNTIMEEFFECT_UNIFORM_TYPE = 4
    FLOAT3X3_SK_RUNTIMEEFFECT_UNIFORM_TYPE = 5
    FLOAT4X4_SK_RUNTIMEEFFECT_UNIFORM_TYPE = 6
    INT_SK_RUNTIMEEFFECT_UNIFORM_TYPE = 7
    INT2_SK_RUNTIMEEFFECT_UNIFORM_TYPE = 8
    INT3_SK_RUNTIMEEFFECT_UNIFORM_TYPE = 9
    INT4_SK_RUNTIMEEFFECT_UNIFORM_TYPE = 10
end

@cenum sk_runtimeeffect_child_type_t::UInt32 begin
    SHADER_SK_RUNTIMEEFFECT_CHILD_TYPE = 0
    COLOR_FILTER_SK_RUNTIMEEFFECT_CHILD_TYPE = 1
    BLENDER_SK_RUNTIMEEFFECT_CHILD_TYPE = 2
end

@cenum sk_runtimeeffect_uniform_flags_t::UInt32 begin
    NONE_SK_RUNTIMEEFFECT_UNIFORM_FLAGS = 0
    ARRAY_SK_RUNTIMEEFFECT_UNIFORM_FLAGS = 1
    COLOR_SK_RUNTIMEEFFECT_UNIFORM_FLAGS = 2
    VERTEX_SK_RUNTIMEEFFECT_UNIFORM_FLAGS = 4
    FRAGMENT_SK_RUNTIMEEFFECT_UNIFORM_FLAGS = 8
    HALF_PRECISION_SK_RUNTIMEEFFECT_UNIFORM_FLAGS = 16
end

struct sk_runtimeeffect_uniform_t
    fName::Ptr{Cchar}
    fNameLength::Csize_t
    fOffset::Csize_t
    fType::sk_runtimeeffect_uniform_type_t
    fCount::Cint
    fFlags::sk_runtimeeffect_uniform_flags_t
end

struct sk_runtimeeffect_child_t
    fName::Ptr{Cchar}
    fNameLength::Csize_t
    fType::sk_runtimeeffect_child_type_t
    fIndex::Cint
end

@cenum sk_filter_mode_t::UInt32 begin
    NEAREST_SK_FILTER_MODE = 0
    LINEAR_SK_FILTER_MODE = 1
end

@cenum sk_mipmap_mode_t::UInt32 begin
    NONE_SK_MIPMAP_MODE = 0
    NEAREST_SK_MIPMAP_MODE = 1
    LINEAR_SK_MIPMAP_MODE = 2
end

struct sk_cubic_resampler_t
    fB::Cfloat
    fC::Cfloat
end

struct sk_sampling_options_t
    fMaxAniso::Cint
    fUseCubic::Bool
    fCubic::sk_cubic_resampler_t
    fFilter::sk_filter_mode_t
    fMipmap::sk_mipmap_mode_t
end

@cenum sk_canvas_savelayerrec_flags_t::UInt32 begin
    NONE_SK_CANVAS_SAVELAYERREC_FLAGS = 0
    PRESERVE_LCD_TEXT_SK_CANVAS_SAVELAYERREC_FLAGS = 2
    INITIALIZE_WITH_PREVIOUS_SK_CANVAS_SAVELAYERREC_FLAGS = 4
    F16_COLOR_TYPE_SK_CANVAS_SAVELAYERREC_FLAGS = 16
end

struct sk_canvas_savelayerrec_t
    fBounds::Ptr{sk_rect_t}
    fPaint::Ptr{sk_paint_t}
    fBackdrop::Ptr{sk_imagefilter_t}
    fFlags::sk_canvas_savelayerrec_flags_t
end

mutable struct skottie_animation_t end

mutable struct skottie_animation_builder_t end

mutable struct skottie_resource_provider_t end

mutable struct skottie_property_observer_t end

mutable struct skottie_logger_t end

mutable struct skottie_marker_observer_t end

mutable struct sksg_invalidation_controller_t end

@cenum skottie_animation_renderflags_t::UInt32 begin
    SKIP_TOP_LEVEL_ISOLATION = 1
    DISABLE_TOP_LEVEL_CLIPPING = 2
end

@cenum skottie_animation_builder_flags_t::UInt32 begin
    NONE_SKOTTIE_ANIMATION_BUILDER_FLAGS = 0
    DEFER_IMAGE_LOADING_SKOTTIE_ANIMATION_BUILDER_FLAGS = 1
    PREFER_EMBEDDED_FONTS_SKOTTIE_ANIMATION_BUILDER_FLAGS = 2
end

struct skottie_animation_builder_stats_t
    fTotalLoadTimeMS::Cfloat
    fJsonParseTimeMS::Cfloat
    fSceneParseTimeMS::Cfloat
    fJsonSize::Csize_t
    fAnimatorCount::Csize_t
end

mutable struct skresources_image_asset_t end

mutable struct skresources_multi_frame_image_asset_t end

mutable struct skresources_external_track_asset_t end

mutable struct skresources_resource_provider_t end

function sk_data_new_empty()
    @ccall LibSkiaSharp.sk_data_new_empty()::Ptr{sk_data_t}
end

function sk_data_new_with_copy(src, length)
    @ccall LibSkiaSharp.sk_data_new_with_copy(src::Ptr{Cvoid}, length::Csize_t)::Ptr{sk_data_t}
end

function sk_data_new_subset(src, offset, length)
    @ccall LibSkiaSharp.sk_data_new_subset(src::Ptr{sk_data_t}, offset::Csize_t, length::Csize_t)::Ptr{sk_data_t}
end

function sk_data_ref(arg1)
    @ccall LibSkiaSharp.sk_data_ref(arg1::Ptr{sk_data_t})::Cvoid
end

function sk_data_unref(arg1)
    @ccall LibSkiaSharp.sk_data_unref(arg1::Ptr{sk_data_t})::Cvoid
end

function sk_data_get_size(arg1)
    @ccall LibSkiaSharp.sk_data_get_size(arg1::Ptr{sk_data_t})::Csize_t
end

function sk_data_get_data(arg1)
    @ccall LibSkiaSharp.sk_data_get_data(arg1::Ptr{sk_data_t})::Ptr{Cvoid}
end

function sk_data_new_from_file(path)
    @ccall LibSkiaSharp.sk_data_new_from_file(path::Ptr{Cchar})::Ptr{sk_data_t}
end

function sk_data_new_from_stream(stream, length)
    @ccall LibSkiaSharp.sk_data_new_from_stream(stream::Ptr{sk_stream_t}, length::Csize_t)::Ptr{sk_data_t}
end

function sk_data_get_bytes(arg1)
    @ccall LibSkiaSharp.sk_data_get_bytes(arg1::Ptr{sk_data_t})::Ptr{UInt8}
end

function sk_data_new_with_proc(ptr, length, proc, ctx)
    @ccall LibSkiaSharp.sk_data_new_with_proc(ptr::Ptr{Cvoid}, length::Csize_t, proc::sk_data_release_proc, ctx::Ptr{Cvoid})::Ptr{sk_data_t}
end

function sk_data_new_uninitialized(size)
    @ccall LibSkiaSharp.sk_data_new_uninitialized(size::Csize_t)::Ptr{sk_data_t}
end

function sk_image_ref(cimage)
    @ccall LibSkiaSharp.sk_image_ref(cimage::Ptr{sk_image_t})::Cvoid
end

function sk_image_unref(cimage)
    @ccall LibSkiaSharp.sk_image_unref(cimage::Ptr{sk_image_t})::Cvoid
end

function sk_image_new_raster_copy(cinfo, pixels, rowBytes)
    @ccall LibSkiaSharp.sk_image_new_raster_copy(cinfo::Ptr{sk_imageinfo_t}, pixels::Ptr{Cvoid}, rowBytes::Csize_t)::Ptr{sk_image_t}
end

function sk_image_new_raster_copy_with_pixmap(pixmap)
    @ccall LibSkiaSharp.sk_image_new_raster_copy_with_pixmap(pixmap::Ptr{sk_pixmap_t})::Ptr{sk_image_t}
end

function sk_image_new_raster_data(cinfo, pixels, rowBytes)
    @ccall LibSkiaSharp.sk_image_new_raster_data(cinfo::Ptr{sk_imageinfo_t}, pixels::Ptr{sk_data_t}, rowBytes::Csize_t)::Ptr{sk_image_t}
end

function sk_image_new_raster(pixmap, releaseProc, context)
    @ccall LibSkiaSharp.sk_image_new_raster(pixmap::Ptr{sk_pixmap_t}, releaseProc::sk_image_raster_release_proc, context::Ptr{Cvoid})::Ptr{sk_image_t}
end

function sk_image_new_from_bitmap(cbitmap)
    @ccall LibSkiaSharp.sk_image_new_from_bitmap(cbitmap::Ptr{sk_bitmap_t})::Ptr{sk_image_t}
end

function sk_image_new_from_encoded(cdata)
    @ccall LibSkiaSharp.sk_image_new_from_encoded(cdata::Ptr{sk_data_t})::Ptr{sk_image_t}
end

function sk_image_new_from_texture(context, texture, origin, colorType, alpha, colorSpace, releaseProc, releaseContext)
    @ccall LibSkiaSharp.sk_image_new_from_texture(context::Ptr{gr_recording_context_t}, texture::Ptr{gr_backendtexture_t}, origin::gr_surfaceorigin_t, colorType::sk_colortype_t, alpha::sk_alphatype_t, colorSpace::Ptr{sk_colorspace_t}, releaseProc::sk_image_texture_release_proc, releaseContext::Ptr{Cvoid})::Ptr{sk_image_t}
end

function sk_image_new_from_adopted_texture(context, texture, origin, colorType, alpha, colorSpace)
    @ccall LibSkiaSharp.sk_image_new_from_adopted_texture(context::Ptr{gr_recording_context_t}, texture::Ptr{gr_backendtexture_t}, origin::gr_surfaceorigin_t, colorType::sk_colortype_t, alpha::sk_alphatype_t, colorSpace::Ptr{sk_colorspace_t})::Ptr{sk_image_t}
end

function sk_image_new_from_picture(picture, dimensions, cmatrix, paint, useFloatingPointBitDepth, colorSpace, props)
    @ccall LibSkiaSharp.sk_image_new_from_picture(picture::Ptr{sk_picture_t}, dimensions::Ptr{sk_isize_t}, cmatrix::Ptr{sk_matrix_t}, paint::Ptr{sk_paint_t}, useFloatingPointBitDepth::Bool, colorSpace::Ptr{sk_colorspace_t}, props::Ptr{sk_surfaceprops_t})::Ptr{sk_image_t}
end

function sk_image_get_width(cimage)
    @ccall LibSkiaSharp.sk_image_get_width(cimage::Ptr{sk_image_t})::Cint
end

function sk_image_get_height(cimage)
    @ccall LibSkiaSharp.sk_image_get_height(cimage::Ptr{sk_image_t})::Cint
end

function sk_image_get_unique_id(cimage)
    @ccall LibSkiaSharp.sk_image_get_unique_id(cimage::Ptr{sk_image_t})::UInt32
end

function sk_image_get_alpha_type(image)
    @ccall LibSkiaSharp.sk_image_get_alpha_type(image::Ptr{sk_image_t})::sk_alphatype_t
end

function sk_image_get_color_type(image)
    @ccall LibSkiaSharp.sk_image_get_color_type(image::Ptr{sk_image_t})::sk_colortype_t
end

function sk_image_get_colorspace(image)
    @ccall LibSkiaSharp.sk_image_get_colorspace(image::Ptr{sk_image_t})::Ptr{sk_colorspace_t}
end

function sk_image_is_alpha_only(image)
    @ccall LibSkiaSharp.sk_image_is_alpha_only(image::Ptr{sk_image_t})::Bool
end

function sk_image_make_shader(image, tileX, tileY, sampling, cmatrix)
    @ccall LibSkiaSharp.sk_image_make_shader(image::Ptr{sk_image_t}, tileX::sk_shader_tilemode_t, tileY::sk_shader_tilemode_t, sampling::Ptr{sk_sampling_options_t}, cmatrix::Ptr{sk_matrix_t})::Ptr{sk_shader_t}
end

function sk_image_make_raw_shader(image, tileX, tileY, sampling, cmatrix)
    @ccall LibSkiaSharp.sk_image_make_raw_shader(image::Ptr{sk_image_t}, tileX::sk_shader_tilemode_t, tileY::sk_shader_tilemode_t, sampling::Ptr{sk_sampling_options_t}, cmatrix::Ptr{sk_matrix_t})::Ptr{sk_shader_t}
end

function sk_image_peek_pixels(image, pixmap)
    @ccall LibSkiaSharp.sk_image_peek_pixels(image::Ptr{sk_image_t}, pixmap::Ptr{sk_pixmap_t})::Bool
end

function sk_image_is_texture_backed(image)
    @ccall LibSkiaSharp.sk_image_is_texture_backed(image::Ptr{sk_image_t})::Bool
end

function sk_image_is_lazy_generated(image)
    @ccall LibSkiaSharp.sk_image_is_lazy_generated(image::Ptr{sk_image_t})::Bool
end

function sk_image_is_valid(image, context)
    @ccall LibSkiaSharp.sk_image_is_valid(image::Ptr{sk_image_t}, context::Ptr{gr_recording_context_t})::Bool
end

function sk_image_read_pixels(image, dstInfo, dstPixels, dstRowBytes, srcX, srcY, cachingHint)
    @ccall LibSkiaSharp.sk_image_read_pixels(image::Ptr{sk_image_t}, dstInfo::Ptr{sk_imageinfo_t}, dstPixels::Ptr{Cvoid}, dstRowBytes::Csize_t, srcX::Cint, srcY::Cint, cachingHint::sk_image_caching_hint_t)::Bool
end

function sk_image_read_pixels_into_pixmap(image, dst, srcX, srcY, cachingHint)
    @ccall LibSkiaSharp.sk_image_read_pixels_into_pixmap(image::Ptr{sk_image_t}, dst::Ptr{sk_pixmap_t}, srcX::Cint, srcY::Cint, cachingHint::sk_image_caching_hint_t)::Bool
end

function sk_image_scale_pixels(image, dst, sampling, cachingHint)
    @ccall LibSkiaSharp.sk_image_scale_pixels(image::Ptr{sk_image_t}, dst::Ptr{sk_pixmap_t}, sampling::Ptr{sk_sampling_options_t}, cachingHint::sk_image_caching_hint_t)::Bool
end

function sk_image_ref_encoded(cimage)
    @ccall LibSkiaSharp.sk_image_ref_encoded(cimage::Ptr{sk_image_t})::Ptr{sk_data_t}
end

function sk_image_make_subset_raster(cimage, subset)
    @ccall LibSkiaSharp.sk_image_make_subset_raster(cimage::Ptr{sk_image_t}, subset::Ptr{sk_irect_t})::Ptr{sk_image_t}
end

function sk_image_make_subset(cimage, context, subset)
    @ccall LibSkiaSharp.sk_image_make_subset(cimage::Ptr{sk_image_t}, context::Ptr{gr_direct_context_t}, subset::Ptr{sk_irect_t})::Ptr{sk_image_t}
end

function sk_image_make_texture_image(cimage, context, mipmapped, budgeted)
    @ccall LibSkiaSharp.sk_image_make_texture_image(cimage::Ptr{sk_image_t}, context::Ptr{gr_direct_context_t}, mipmapped::Bool, budgeted::Bool)::Ptr{sk_image_t}
end

function sk_image_make_non_texture_image(cimage)
    @ccall LibSkiaSharp.sk_image_make_non_texture_image(cimage::Ptr{sk_image_t})::Ptr{sk_image_t}
end

function sk_image_make_raster_image(cimage)
    @ccall LibSkiaSharp.sk_image_make_raster_image(cimage::Ptr{sk_image_t})::Ptr{sk_image_t}
end

function sk_image_make_with_filter_raster(cimage, filter, subset, clipBounds, outSubset, outOffset)
    @ccall LibSkiaSharp.sk_image_make_with_filter_raster(cimage::Ptr{sk_image_t}, filter::Ptr{sk_imagefilter_t}, subset::Ptr{sk_irect_t}, clipBounds::Ptr{sk_irect_t}, outSubset::Ptr{sk_irect_t}, outOffset::Ptr{sk_ipoint_t})::Ptr{sk_image_t}
end

function sk_image_make_with_filter(cimage, context, filter, subset, clipBounds, outSubset, outOffset)
    @ccall LibSkiaSharp.sk_image_make_with_filter(cimage::Ptr{sk_image_t}, context::Ptr{gr_recording_context_t}, filter::Ptr{sk_imagefilter_t}, subset::Ptr{sk_irect_t}, clipBounds::Ptr{sk_irect_t}, outSubset::Ptr{sk_irect_t}, outOffset::Ptr{sk_ipoint_t})::Ptr{sk_image_t}
end

function sk_canvas_destroy(ccanvas)
    @ccall LibSkiaSharp.sk_canvas_destroy(ccanvas::Ptr{sk_canvas_t})::Cvoid
end

function sk_canvas_clear(ccanvas, color)
    @ccall LibSkiaSharp.sk_canvas_clear(ccanvas::Ptr{sk_canvas_t}, color::sk_color_t)::Cvoid
end

function sk_canvas_clear_color4f(ccanvas, color)
    @ccall LibSkiaSharp.sk_canvas_clear_color4f(ccanvas::Ptr{sk_canvas_t}, color::sk_color4f_t)::Cvoid
end

function sk_canvas_discard(ccanvas)
    @ccall LibSkiaSharp.sk_canvas_discard(ccanvas::Ptr{sk_canvas_t})::Cvoid
end

function sk_canvas_get_save_count(ccanvas)
    @ccall LibSkiaSharp.sk_canvas_get_save_count(ccanvas::Ptr{sk_canvas_t})::Cint
end

function sk_canvas_restore_to_count(ccanvas, saveCount)
    @ccall LibSkiaSharp.sk_canvas_restore_to_count(ccanvas::Ptr{sk_canvas_t}, saveCount::Cint)::Cvoid
end

function sk_canvas_draw_color(ccanvas, color, cmode)
    @ccall LibSkiaSharp.sk_canvas_draw_color(ccanvas::Ptr{sk_canvas_t}, color::sk_color_t, cmode::sk_blendmode_t)::Cvoid
end

function sk_canvas_draw_color4f(ccanvas, color, cmode)
    @ccall LibSkiaSharp.sk_canvas_draw_color4f(ccanvas::Ptr{sk_canvas_t}, color::sk_color4f_t, cmode::sk_blendmode_t)::Cvoid
end

function sk_canvas_draw_points(ccanvas, pointMode, count, points, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_points(ccanvas::Ptr{sk_canvas_t}, pointMode::sk_point_mode_t, count::Csize_t, points::Ptr{sk_point_t}, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_point(ccanvas, x, y, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_point(ccanvas::Ptr{sk_canvas_t}, x::Cfloat, y::Cfloat, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_line(ccanvas, x0, y0, x1, y1, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_line(ccanvas::Ptr{sk_canvas_t}, x0::Cfloat, y0::Cfloat, x1::Cfloat, y1::Cfloat, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_simple_text(ccanvas, text, byte_length, encoding, x, y, cfont, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_simple_text(ccanvas::Ptr{sk_canvas_t}, text::Ptr{Cvoid}, byte_length::Csize_t, encoding::sk_text_encoding_t, x::Cfloat, y::Cfloat, cfont::Ptr{sk_font_t}, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_text_blob(ccanvas, text, x, y, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_text_blob(ccanvas::Ptr{sk_canvas_t}, text::Ptr{sk_textblob_t}, x::Cfloat, y::Cfloat, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_reset_matrix(ccanvas)
    @ccall LibSkiaSharp.sk_canvas_reset_matrix(ccanvas::Ptr{sk_canvas_t})::Cvoid
end

function sk_canvas_set_matrix(ccanvas, cmatrix)
    @ccall LibSkiaSharp.sk_canvas_set_matrix(ccanvas::Ptr{sk_canvas_t}, cmatrix::Ptr{sk_matrix44_t})::Cvoid
end

function sk_canvas_get_matrix(ccanvas, cmatrix)
    @ccall LibSkiaSharp.sk_canvas_get_matrix(ccanvas::Ptr{sk_canvas_t}, cmatrix::Ptr{sk_matrix44_t})::Cvoid
end

function sk_canvas_draw_round_rect(ccanvas, crect, rx, ry, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_round_rect(ccanvas::Ptr{sk_canvas_t}, crect::Ptr{sk_rect_t}, rx::Cfloat, ry::Cfloat, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_clip_rect_with_operation(ccanvas, crect, op, doAA)
    @ccall LibSkiaSharp.sk_canvas_clip_rect_with_operation(ccanvas::Ptr{sk_canvas_t}, crect::Ptr{sk_rect_t}, op::sk_clipop_t, doAA::Bool)::Cvoid
end

function sk_canvas_clip_path_with_operation(ccanvas, cpath, op, doAA)
    @ccall LibSkiaSharp.sk_canvas_clip_path_with_operation(ccanvas::Ptr{sk_canvas_t}, cpath::Ptr{sk_path_t}, op::sk_clipop_t, doAA::Bool)::Cvoid
end

function sk_canvas_clip_rrect_with_operation(ccanvas, crect, op, doAA)
    @ccall LibSkiaSharp.sk_canvas_clip_rrect_with_operation(ccanvas::Ptr{sk_canvas_t}, crect::Ptr{sk_rrect_t}, op::sk_clipop_t, doAA::Bool)::Cvoid
end

function sk_canvas_get_local_clip_bounds(ccanvas, cbounds)
    @ccall LibSkiaSharp.sk_canvas_get_local_clip_bounds(ccanvas::Ptr{sk_canvas_t}, cbounds::Ptr{sk_rect_t})::Bool
end

function sk_canvas_get_device_clip_bounds(ccanvas, cbounds)
    @ccall LibSkiaSharp.sk_canvas_get_device_clip_bounds(ccanvas::Ptr{sk_canvas_t}, cbounds::Ptr{sk_irect_t})::Bool
end

function sk_canvas_save(ccanvas)
    @ccall LibSkiaSharp.sk_canvas_save(ccanvas::Ptr{sk_canvas_t})::Cint
end

function sk_canvas_save_layer(ccanvas, crect, cpaint)
    @ccall LibSkiaSharp.sk_canvas_save_layer(ccanvas::Ptr{sk_canvas_t}, crect::Ptr{sk_rect_t}, cpaint::Ptr{sk_paint_t})::Cint
end

function sk_canvas_save_layer_rec(ccanvas, crec)
    @ccall LibSkiaSharp.sk_canvas_save_layer_rec(ccanvas::Ptr{sk_canvas_t}, crec::Ptr{sk_canvas_savelayerrec_t})::Cint
end

function sk_canvas_restore(ccanvas)
    @ccall LibSkiaSharp.sk_canvas_restore(ccanvas::Ptr{sk_canvas_t})::Cvoid
end

function sk_canvas_translate(ccanvas, dx, dy)
    @ccall LibSkiaSharp.sk_canvas_translate(ccanvas::Ptr{sk_canvas_t}, dx::Cfloat, dy::Cfloat)::Cvoid
end

function sk_canvas_scale(ccanvas, sx, sy)
    @ccall LibSkiaSharp.sk_canvas_scale(ccanvas::Ptr{sk_canvas_t}, sx::Cfloat, sy::Cfloat)::Cvoid
end

function sk_canvas_rotate_degrees(ccanvas, degrees)
    @ccall LibSkiaSharp.sk_canvas_rotate_degrees(ccanvas::Ptr{sk_canvas_t}, degrees::Cfloat)::Cvoid
end

function sk_canvas_rotate_radians(ccanvas, radians)
    @ccall LibSkiaSharp.sk_canvas_rotate_radians(ccanvas::Ptr{sk_canvas_t}, radians::Cfloat)::Cvoid
end

function sk_canvas_skew(ccanvas, sx, sy)
    @ccall LibSkiaSharp.sk_canvas_skew(ccanvas::Ptr{sk_canvas_t}, sx::Cfloat, sy::Cfloat)::Cvoid
end

function sk_canvas_concat(ccanvas, cmatrix)
    @ccall LibSkiaSharp.sk_canvas_concat(ccanvas::Ptr{sk_canvas_t}, cmatrix::Ptr{sk_matrix44_t})::Cvoid
end

function sk_canvas_quick_reject(ccanvas, crect)
    @ccall LibSkiaSharp.sk_canvas_quick_reject(ccanvas::Ptr{sk_canvas_t}, crect::Ptr{sk_rect_t})::Bool
end

function sk_canvas_clip_region(ccanvas, region, op)
    @ccall LibSkiaSharp.sk_canvas_clip_region(ccanvas::Ptr{sk_canvas_t}, region::Ptr{sk_region_t}, op::sk_clipop_t)::Cvoid
end

function sk_canvas_draw_paint(ccanvas, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_paint(ccanvas::Ptr{sk_canvas_t}, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_region(ccanvas, cregion, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_region(ccanvas::Ptr{sk_canvas_t}, cregion::Ptr{sk_region_t}, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_rect(ccanvas, crect, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_rect(ccanvas::Ptr{sk_canvas_t}, crect::Ptr{sk_rect_t}, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_rrect(ccanvas, crect, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_rrect(ccanvas::Ptr{sk_canvas_t}, crect::Ptr{sk_rrect_t}, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_circle(ccanvas, cx, cy, rad, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_circle(ccanvas::Ptr{sk_canvas_t}, cx::Cfloat, cy::Cfloat, rad::Cfloat, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_oval(ccanvas, crect, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_oval(ccanvas::Ptr{sk_canvas_t}, crect::Ptr{sk_rect_t}, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_path(ccanvas, cpath, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_path(ccanvas::Ptr{sk_canvas_t}, cpath::Ptr{sk_path_t}, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_image(ccanvas, cimage, x, y, sampling, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_image(ccanvas::Ptr{sk_canvas_t}, cimage::Ptr{sk_image_t}, x::Cfloat, y::Cfloat, sampling::Ptr{sk_sampling_options_t}, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_image_rect(ccanvas, cimage, csrcR, cdstR, sampling, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_image_rect(ccanvas::Ptr{sk_canvas_t}, cimage::Ptr{sk_image_t}, csrcR::Ptr{sk_rect_t}, cdstR::Ptr{sk_rect_t}, sampling::Ptr{sk_sampling_options_t}, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_picture(ccanvas, cpicture, cmatrix, cpaint)
    @ccall LibSkiaSharp.sk_canvas_draw_picture(ccanvas::Ptr{sk_canvas_t}, cpicture::Ptr{sk_picture_t}, cmatrix::Ptr{sk_matrix_t}, cpaint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_drawable(ccanvas, cdrawable, cmatrix)
    @ccall LibSkiaSharp.sk_canvas_draw_drawable(ccanvas::Ptr{sk_canvas_t}, cdrawable::Ptr{sk_drawable_t}, cmatrix::Ptr{sk_matrix_t})::Cvoid
end

function sk_canvas_new_from_bitmap(bitmap)
    @ccall LibSkiaSharp.sk_canvas_new_from_bitmap(bitmap::Ptr{sk_bitmap_t})::Ptr{sk_canvas_t}
end

function sk_canvas_new_from_raster(cinfo, pixels, rowBytes, props)
    @ccall LibSkiaSharp.sk_canvas_new_from_raster(cinfo::Ptr{sk_imageinfo_t}, pixels::Ptr{Cvoid}, rowBytes::Csize_t, props::Ptr{sk_surfaceprops_t})::Ptr{sk_canvas_t}
end

function sk_canvas_draw_annotation(t, rect, key, value)
    @ccall LibSkiaSharp.sk_canvas_draw_annotation(t::Ptr{sk_canvas_t}, rect::Ptr{sk_rect_t}, key::Ptr{Cchar}, value::Ptr{sk_data_t})::Cvoid
end

function sk_canvas_draw_url_annotation(t, rect, value)
    @ccall LibSkiaSharp.sk_canvas_draw_url_annotation(t::Ptr{sk_canvas_t}, rect::Ptr{sk_rect_t}, value::Ptr{sk_data_t})::Cvoid
end

function sk_canvas_draw_named_destination_annotation(t, point, value)
    @ccall LibSkiaSharp.sk_canvas_draw_named_destination_annotation(t::Ptr{sk_canvas_t}, point::Ptr{sk_point_t}, value::Ptr{sk_data_t})::Cvoid
end

function sk_canvas_draw_link_destination_annotation(t, rect, value)
    @ccall LibSkiaSharp.sk_canvas_draw_link_destination_annotation(t::Ptr{sk_canvas_t}, rect::Ptr{sk_rect_t}, value::Ptr{sk_data_t})::Cvoid
end

function sk_canvas_draw_image_lattice(ccanvas, image, lattice, dst, mode, paint)
    @ccall LibSkiaSharp.sk_canvas_draw_image_lattice(ccanvas::Ptr{sk_canvas_t}, image::Ptr{sk_image_t}, lattice::Ptr{sk_lattice_t}, dst::Ptr{sk_rect_t}, mode::sk_filter_mode_t, paint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_image_nine(ccanvas, image, center, dst, mode, paint)
    @ccall LibSkiaSharp.sk_canvas_draw_image_nine(ccanvas::Ptr{sk_canvas_t}, image::Ptr{sk_image_t}, center::Ptr{sk_irect_t}, dst::Ptr{sk_rect_t}, mode::sk_filter_mode_t, paint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_vertices(ccanvas, vertices, mode, paint)
    @ccall LibSkiaSharp.sk_canvas_draw_vertices(ccanvas::Ptr{sk_canvas_t}, vertices::Ptr{sk_vertices_t}, mode::sk_blendmode_t, paint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_arc(ccanvas, oval, startAngle, sweepAngle, useCenter, paint)
    @ccall LibSkiaSharp.sk_canvas_draw_arc(ccanvas::Ptr{sk_canvas_t}, oval::Ptr{sk_rect_t}, startAngle::Cfloat, sweepAngle::Cfloat, useCenter::Bool, paint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_drrect(ccanvas, outer, inner, paint)
    @ccall LibSkiaSharp.sk_canvas_draw_drrect(ccanvas::Ptr{sk_canvas_t}, outer::Ptr{sk_rrect_t}, inner::Ptr{sk_rrect_t}, paint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_atlas(ccanvas, atlas, xform, tex, colors, count, mode, sampling, cullRect, paint)
    @ccall LibSkiaSharp.sk_canvas_draw_atlas(ccanvas::Ptr{sk_canvas_t}, atlas::Ptr{sk_image_t}, xform::Ptr{sk_rsxform_t}, tex::Ptr{sk_rect_t}, colors::Ptr{sk_color_t}, count::Cint, mode::sk_blendmode_t, sampling::Ptr{sk_sampling_options_t}, cullRect::Ptr{sk_rect_t}, paint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_draw_patch(ccanvas, cubics, colors, texCoords, mode, paint)
    @ccall LibSkiaSharp.sk_canvas_draw_patch(ccanvas::Ptr{sk_canvas_t}, cubics::Ptr{sk_point_t}, colors::Ptr{sk_color_t}, texCoords::Ptr{sk_point_t}, mode::sk_blendmode_t, paint::Ptr{sk_paint_t})::Cvoid
end

function sk_canvas_is_clip_empty(ccanvas)
    @ccall LibSkiaSharp.sk_canvas_is_clip_empty(ccanvas::Ptr{sk_canvas_t})::Bool
end

function sk_canvas_is_clip_rect(ccanvas)
    @ccall LibSkiaSharp.sk_canvas_is_clip_rect(ccanvas::Ptr{sk_canvas_t})::Bool
end

function sk_nodraw_canvas_new(width, height)
    @ccall LibSkiaSharp.sk_nodraw_canvas_new(width::Cint, height::Cint)::Ptr{sk_nodraw_canvas_t}
end

function sk_nodraw_canvas_destroy(t)
    @ccall LibSkiaSharp.sk_nodraw_canvas_destroy(t::Ptr{sk_nodraw_canvas_t})::Cvoid
end

function sk_nway_canvas_new(width, height)
    @ccall LibSkiaSharp.sk_nway_canvas_new(width::Cint, height::Cint)::Ptr{sk_nway_canvas_t}
end

function sk_nway_canvas_destroy(t)
    @ccall LibSkiaSharp.sk_nway_canvas_destroy(t::Ptr{sk_nway_canvas_t})::Cvoid
end

function sk_nway_canvas_add_canvas(t, canvas)
    @ccall LibSkiaSharp.sk_nway_canvas_add_canvas(t::Ptr{sk_nway_canvas_t}, canvas::Ptr{sk_canvas_t})::Cvoid
end

function sk_nway_canvas_remove_canvas(t, canvas)
    @ccall LibSkiaSharp.sk_nway_canvas_remove_canvas(t::Ptr{sk_nway_canvas_t}, canvas::Ptr{sk_canvas_t})::Cvoid
end

function sk_nway_canvas_remove_all(t)
    @ccall LibSkiaSharp.sk_nway_canvas_remove_all(t::Ptr{sk_nway_canvas_t})::Cvoid
end

function sk_overdraw_canvas_new(canvas)
    @ccall LibSkiaSharp.sk_overdraw_canvas_new(canvas::Ptr{sk_canvas_t})::Ptr{sk_overdraw_canvas_t}
end

function sk_overdraw_canvas_destroy(canvas)
    @ccall LibSkiaSharp.sk_overdraw_canvas_destroy(canvas::Ptr{sk_overdraw_canvas_t})::Cvoid
end

function sk_get_recording_context(canvas)
    @ccall LibSkiaSharp.sk_get_recording_context(canvas::Ptr{sk_canvas_t})::Ptr{gr_recording_context_t}
end

function sk_get_surface(canvas)
    @ccall LibSkiaSharp.sk_get_surface(canvas::Ptr{sk_canvas_t})::Ptr{sk_surface_t}
end

function sk_surface_new_null(width, height)
    @ccall LibSkiaSharp.sk_surface_new_null(width::Cint, height::Cint)::Ptr{sk_surface_t}
end

function sk_surface_new_raster(arg1, rowBytes, arg3)
    @ccall LibSkiaSharp.sk_surface_new_raster(arg1::Ptr{sk_imageinfo_t}, rowBytes::Csize_t, arg3::Ptr{sk_surfaceprops_t})::Ptr{sk_surface_t}
end

function sk_surface_new_raster_direct(arg1, pixels, rowBytes, releaseProc, context, props)
    @ccall LibSkiaSharp.sk_surface_new_raster_direct(arg1::Ptr{sk_imageinfo_t}, pixels::Ptr{Cvoid}, rowBytes::Csize_t, releaseProc::sk_surface_raster_release_proc, context::Ptr{Cvoid}, props::Ptr{sk_surfaceprops_t})::Ptr{sk_surface_t}
end

function sk_surface_new_backend_texture(context, texture, origin, samples, colorType, colorspace, props)
    @ccall LibSkiaSharp.sk_surface_new_backend_texture(context::Ptr{gr_recording_context_t}, texture::Ptr{gr_backendtexture_t}, origin::gr_surfaceorigin_t, samples::Cint, colorType::sk_colortype_t, colorspace::Ptr{sk_colorspace_t}, props::Ptr{sk_surfaceprops_t})::Ptr{sk_surface_t}
end

function sk_surface_new_backend_render_target(context, target, origin, colorType, colorspace, props)
    @ccall LibSkiaSharp.sk_surface_new_backend_render_target(context::Ptr{gr_recording_context_t}, target::Ptr{gr_backendrendertarget_t}, origin::gr_surfaceorigin_t, colorType::sk_colortype_t, colorspace::Ptr{sk_colorspace_t}, props::Ptr{sk_surfaceprops_t})::Ptr{sk_surface_t}
end

function sk_surface_new_render_target(context, budgeted, cinfo, sampleCount, origin, props, shouldCreateWithMips)
    @ccall LibSkiaSharp.sk_surface_new_render_target(context::Ptr{gr_recording_context_t}, budgeted::Bool, cinfo::Ptr{sk_imageinfo_t}, sampleCount::Cint, origin::gr_surfaceorigin_t, props::Ptr{sk_surfaceprops_t}, shouldCreateWithMips::Bool)::Ptr{sk_surface_t}
end

function sk_surface_new_metal_layer(context, layer, origin, sampleCount, colorType, colorspace, props, drawable)
    @ccall LibSkiaSharp.sk_surface_new_metal_layer(context::Ptr{gr_recording_context_t}, layer::Ptr{Cvoid}, origin::gr_surfaceorigin_t, sampleCount::Cint, colorType::sk_colortype_t, colorspace::Ptr{sk_colorspace_t}, props::Ptr{sk_surfaceprops_t}, drawable::Ptr{Ptr{Cvoid}})::Ptr{sk_surface_t}
end

function sk_surface_new_metal_view(context, mtkView, origin, sampleCount, colorType, colorspace, props)
    @ccall LibSkiaSharp.sk_surface_new_metal_view(context::Ptr{gr_recording_context_t}, mtkView::Ptr{Cvoid}, origin::gr_surfaceorigin_t, sampleCount::Cint, colorType::sk_colortype_t, colorspace::Ptr{sk_colorspace_t}, props::Ptr{sk_surfaceprops_t})::Ptr{sk_surface_t}
end

function sk_surface_unref(arg1)
    @ccall LibSkiaSharp.sk_surface_unref(arg1::Ptr{sk_surface_t})::Cvoid
end

function sk_surface_get_canvas(arg1)
    @ccall LibSkiaSharp.sk_surface_get_canvas(arg1::Ptr{sk_surface_t})::Ptr{sk_canvas_t}
end

function sk_surface_new_image_snapshot(arg1)
    @ccall LibSkiaSharp.sk_surface_new_image_snapshot(arg1::Ptr{sk_surface_t})::Ptr{sk_image_t}
end

function sk_surface_new_image_snapshot_with_crop(surface, bounds)
    @ccall LibSkiaSharp.sk_surface_new_image_snapshot_with_crop(surface::Ptr{sk_surface_t}, bounds::Ptr{sk_irect_t})::Ptr{sk_image_t}
end

function sk_surface_draw(surface, canvas, x, y, paint)
    @ccall LibSkiaSharp.sk_surface_draw(surface::Ptr{sk_surface_t}, canvas::Ptr{sk_canvas_t}, x::Cfloat, y::Cfloat, paint::Ptr{sk_paint_t})::Cvoid
end

function sk_surface_peek_pixels(surface, pixmap)
    @ccall LibSkiaSharp.sk_surface_peek_pixels(surface::Ptr{sk_surface_t}, pixmap::Ptr{sk_pixmap_t})::Bool
end

function sk_surface_read_pixels(surface, dstInfo, dstPixels, dstRowBytes, srcX, srcY)
    @ccall LibSkiaSharp.sk_surface_read_pixels(surface::Ptr{sk_surface_t}, dstInfo::Ptr{sk_imageinfo_t}, dstPixels::Ptr{Cvoid}, dstRowBytes::Csize_t, srcX::Cint, srcY::Cint)::Bool
end

function sk_surface_get_props(surface)
    @ccall LibSkiaSharp.sk_surface_get_props(surface::Ptr{sk_surface_t})::Ptr{sk_surfaceprops_t}
end

function sk_surface_get_recording_context(surface)
    @ccall LibSkiaSharp.sk_surface_get_recording_context(surface::Ptr{sk_surface_t})::Ptr{gr_recording_context_t}
end

function sk_surfaceprops_new(flags, geometry)
    @ccall LibSkiaSharp.sk_surfaceprops_new(flags::UInt32, geometry::sk_pixelgeometry_t)::Ptr{sk_surfaceprops_t}
end

function sk_surfaceprops_delete(props)
    @ccall LibSkiaSharp.sk_surfaceprops_delete(props::Ptr{sk_surfaceprops_t})::Cvoid
end

function sk_surfaceprops_get_flags(props)
    @ccall LibSkiaSharp.sk_surfaceprops_get_flags(props::Ptr{sk_surfaceprops_t})::UInt32
end

function sk_surfaceprops_get_pixel_geometry(props)
    @ccall LibSkiaSharp.sk_surfaceprops_get_pixel_geometry(props::Ptr{sk_surfaceprops_t})::sk_pixelgeometry_t
end

function sk_paint_new()
    @ccall LibSkiaSharp.sk_paint_new()::Ptr{sk_paint_t}
end

function sk_paint_clone(arg1)
    @ccall LibSkiaSharp.sk_paint_clone(arg1::Ptr{sk_paint_t})::Ptr{sk_paint_t}
end

function sk_paint_delete(arg1)
    @ccall LibSkiaSharp.sk_paint_delete(arg1::Ptr{sk_paint_t})::Cvoid
end

function sk_paint_reset(arg1)
    @ccall LibSkiaSharp.sk_paint_reset(arg1::Ptr{sk_paint_t})::Cvoid
end

function sk_paint_is_antialias(arg1)
    @ccall LibSkiaSharp.sk_paint_is_antialias(arg1::Ptr{sk_paint_t})::Bool
end

function sk_paint_set_antialias(arg1, arg2)
    @ccall LibSkiaSharp.sk_paint_set_antialias(arg1::Ptr{sk_paint_t}, arg2::Bool)::Cvoid
end

function sk_paint_get_color(arg1)
    @ccall LibSkiaSharp.sk_paint_get_color(arg1::Ptr{sk_paint_t})::sk_color_t
end

function sk_paint_get_color4f(paint, color)
    @ccall LibSkiaSharp.sk_paint_get_color4f(paint::Ptr{sk_paint_t}, color::Ptr{sk_color4f_t})::Cvoid
end

function sk_paint_set_color(arg1, arg2)
    @ccall LibSkiaSharp.sk_paint_set_color(arg1::Ptr{sk_paint_t}, arg2::sk_color_t)::Cvoid
end

function sk_paint_set_color4f(paint, color, colorspace)
    @ccall LibSkiaSharp.sk_paint_set_color4f(paint::Ptr{sk_paint_t}, color::Ptr{sk_color4f_t}, colorspace::Ptr{sk_colorspace_t})::Cvoid
end

function sk_paint_get_style(arg1)
    @ccall LibSkiaSharp.sk_paint_get_style(arg1::Ptr{sk_paint_t})::sk_paint_style_t
end

function sk_paint_set_style(arg1, arg2)
    @ccall LibSkiaSharp.sk_paint_set_style(arg1::Ptr{sk_paint_t}, arg2::sk_paint_style_t)::Cvoid
end

function sk_paint_get_stroke_width(arg1)
    @ccall LibSkiaSharp.sk_paint_get_stroke_width(arg1::Ptr{sk_paint_t})::Cfloat
end

function sk_paint_set_stroke_width(arg1, width)
    @ccall LibSkiaSharp.sk_paint_set_stroke_width(arg1::Ptr{sk_paint_t}, width::Cfloat)::Cvoid
end

function sk_paint_get_stroke_miter(arg1)
    @ccall LibSkiaSharp.sk_paint_get_stroke_miter(arg1::Ptr{sk_paint_t})::Cfloat
end

function sk_paint_set_stroke_miter(arg1, miter)
    @ccall LibSkiaSharp.sk_paint_set_stroke_miter(arg1::Ptr{sk_paint_t}, miter::Cfloat)::Cvoid
end

function sk_paint_get_stroke_cap(arg1)
    @ccall LibSkiaSharp.sk_paint_get_stroke_cap(arg1::Ptr{sk_paint_t})::sk_stroke_cap_t
end

function sk_paint_set_stroke_cap(arg1, arg2)
    @ccall LibSkiaSharp.sk_paint_set_stroke_cap(arg1::Ptr{sk_paint_t}, arg2::sk_stroke_cap_t)::Cvoid
end

function sk_paint_get_stroke_join(arg1)
    @ccall LibSkiaSharp.sk_paint_get_stroke_join(arg1::Ptr{sk_paint_t})::sk_stroke_join_t
end

function sk_paint_set_stroke_join(arg1, arg2)
    @ccall LibSkiaSharp.sk_paint_set_stroke_join(arg1::Ptr{sk_paint_t}, arg2::sk_stroke_join_t)::Cvoid
end

function sk_paint_set_shader(arg1, arg2)
    @ccall LibSkiaSharp.sk_paint_set_shader(arg1::Ptr{sk_paint_t}, arg2::Ptr{sk_shader_t})::Cvoid
end

function sk_paint_set_maskfilter(arg1, arg2)
    @ccall LibSkiaSharp.sk_paint_set_maskfilter(arg1::Ptr{sk_paint_t}, arg2::Ptr{sk_maskfilter_t})::Cvoid
end

function sk_paint_set_blendmode(arg1, arg2)
    @ccall LibSkiaSharp.sk_paint_set_blendmode(arg1::Ptr{sk_paint_t}, arg2::sk_blendmode_t)::Cvoid
end

function sk_paint_set_blender(paint, blender)
    @ccall LibSkiaSharp.sk_paint_set_blender(paint::Ptr{sk_paint_t}, blender::Ptr{sk_blender_t})::Cvoid
end

function sk_paint_is_dither(arg1)
    @ccall LibSkiaSharp.sk_paint_is_dither(arg1::Ptr{sk_paint_t})::Bool
end

function sk_paint_set_dither(arg1, arg2)
    @ccall LibSkiaSharp.sk_paint_set_dither(arg1::Ptr{sk_paint_t}, arg2::Bool)::Cvoid
end

function sk_paint_get_shader(arg1)
    @ccall LibSkiaSharp.sk_paint_get_shader(arg1::Ptr{sk_paint_t})::Ptr{sk_shader_t}
end

function sk_paint_get_maskfilter(arg1)
    @ccall LibSkiaSharp.sk_paint_get_maskfilter(arg1::Ptr{sk_paint_t})::Ptr{sk_maskfilter_t}
end

function sk_paint_set_colorfilter(arg1, arg2)
    @ccall LibSkiaSharp.sk_paint_set_colorfilter(arg1::Ptr{sk_paint_t}, arg2::Ptr{sk_colorfilter_t})::Cvoid
end

function sk_paint_get_colorfilter(arg1)
    @ccall LibSkiaSharp.sk_paint_get_colorfilter(arg1::Ptr{sk_paint_t})::Ptr{sk_colorfilter_t}
end

function sk_paint_set_imagefilter(arg1, arg2)
    @ccall LibSkiaSharp.sk_paint_set_imagefilter(arg1::Ptr{sk_paint_t}, arg2::Ptr{sk_imagefilter_t})::Cvoid
end

function sk_paint_get_imagefilter(arg1)
    @ccall LibSkiaSharp.sk_paint_get_imagefilter(arg1::Ptr{sk_paint_t})::Ptr{sk_imagefilter_t}
end

function sk_paint_get_blendmode(arg1)
    @ccall LibSkiaSharp.sk_paint_get_blendmode(arg1::Ptr{sk_paint_t})::sk_blendmode_t
end

function sk_paint_get_blender(cpaint)
    @ccall LibSkiaSharp.sk_paint_get_blender(cpaint::Ptr{sk_paint_t})::Ptr{sk_blender_t}
end

function sk_paint_get_path_effect(cpaint)
    @ccall LibSkiaSharp.sk_paint_get_path_effect(cpaint::Ptr{sk_paint_t})::Ptr{sk_path_effect_t}
end

function sk_paint_set_path_effect(cpaint, effect)
    @ccall LibSkiaSharp.sk_paint_set_path_effect(cpaint::Ptr{sk_paint_t}, effect::Ptr{sk_path_effect_t})::Cvoid
end

function sk_paint_get_fill_path(cpaint, src, dst, cullRect, cmatrix)
    @ccall LibSkiaSharp.sk_paint_get_fill_path(cpaint::Ptr{sk_paint_t}, src::Ptr{sk_path_t}, dst::Ptr{sk_path_t}, cullRect::Ptr{sk_rect_t}, cmatrix::Ptr{sk_matrix_t})::Bool
end

function sk_path_new()
    @ccall LibSkiaSharp.sk_path_new()::Ptr{sk_path_t}
end

function sk_path_delete(arg1)
    @ccall LibSkiaSharp.sk_path_delete(arg1::Ptr{sk_path_t})::Cvoid
end

function sk_path_move_to(arg1, x, y)
    @ccall LibSkiaSharp.sk_path_move_to(arg1::Ptr{sk_path_t}, x::Cfloat, y::Cfloat)::Cvoid
end

function sk_path_line_to(arg1, x, y)
    @ccall LibSkiaSharp.sk_path_line_to(arg1::Ptr{sk_path_t}, x::Cfloat, y::Cfloat)::Cvoid
end

function sk_path_quad_to(arg1, x0, y0, x1, y1)
    @ccall LibSkiaSharp.sk_path_quad_to(arg1::Ptr{sk_path_t}, x0::Cfloat, y0::Cfloat, x1::Cfloat, y1::Cfloat)::Cvoid
end

function sk_path_conic_to(arg1, x0, y0, x1, y1, w)
    @ccall LibSkiaSharp.sk_path_conic_to(arg1::Ptr{sk_path_t}, x0::Cfloat, y0::Cfloat, x1::Cfloat, y1::Cfloat, w::Cfloat)::Cvoid
end

function sk_path_cubic_to(arg1, x0, y0, x1, y1, x2, y2)
    @ccall LibSkiaSharp.sk_path_cubic_to(arg1::Ptr{sk_path_t}, x0::Cfloat, y0::Cfloat, x1::Cfloat, y1::Cfloat, x2::Cfloat, y2::Cfloat)::Cvoid
end

function sk_path_arc_to(arg1, rx, ry, xAxisRotate, largeArc, sweep, x, y)
    @ccall LibSkiaSharp.sk_path_arc_to(arg1::Ptr{sk_path_t}, rx::Cfloat, ry::Cfloat, xAxisRotate::Cfloat, largeArc::sk_path_arc_size_t, sweep::sk_path_direction_t, x::Cfloat, y::Cfloat)::Cvoid
end

function sk_path_rarc_to(arg1, rx, ry, xAxisRotate, largeArc, sweep, x, y)
    @ccall LibSkiaSharp.sk_path_rarc_to(arg1::Ptr{sk_path_t}, rx::Cfloat, ry::Cfloat, xAxisRotate::Cfloat, largeArc::sk_path_arc_size_t, sweep::sk_path_direction_t, x::Cfloat, y::Cfloat)::Cvoid
end

function sk_path_arc_to_with_oval(arg1, oval, startAngle, sweepAngle, forceMoveTo)
    @ccall LibSkiaSharp.sk_path_arc_to_with_oval(arg1::Ptr{sk_path_t}, oval::Ptr{sk_rect_t}, startAngle::Cfloat, sweepAngle::Cfloat, forceMoveTo::Bool)::Cvoid
end

function sk_path_arc_to_with_points(arg1, x1, y1, x2, y2, radius)
    @ccall LibSkiaSharp.sk_path_arc_to_with_points(arg1::Ptr{sk_path_t}, x1::Cfloat, y1::Cfloat, x2::Cfloat, y2::Cfloat, radius::Cfloat)::Cvoid
end

function sk_path_close(arg1)
    @ccall LibSkiaSharp.sk_path_close(arg1::Ptr{sk_path_t})::Cvoid
end

function sk_path_add_rect(arg1, arg2, arg3)
    @ccall LibSkiaSharp.sk_path_add_rect(arg1::Ptr{sk_path_t}, arg2::Ptr{sk_rect_t}, arg3::sk_path_direction_t)::Cvoid
end

function sk_path_add_rrect(arg1, arg2, arg3)
    @ccall LibSkiaSharp.sk_path_add_rrect(arg1::Ptr{sk_path_t}, arg2::Ptr{sk_rrect_t}, arg3::sk_path_direction_t)::Cvoid
end

function sk_path_add_rrect_start(arg1, arg2, arg3, arg4)
    @ccall LibSkiaSharp.sk_path_add_rrect_start(arg1::Ptr{sk_path_t}, arg2::Ptr{sk_rrect_t}, arg3::sk_path_direction_t, arg4::UInt32)::Cvoid
end

function sk_path_add_rounded_rect(arg1, arg2, arg3, arg4, arg5)
    @ccall LibSkiaSharp.sk_path_add_rounded_rect(arg1::Ptr{sk_path_t}, arg2::Ptr{sk_rect_t}, arg3::Cfloat, arg4::Cfloat, arg5::sk_path_direction_t)::Cvoid
end

function sk_path_add_oval(arg1, arg2, arg3)
    @ccall LibSkiaSharp.sk_path_add_oval(arg1::Ptr{sk_path_t}, arg2::Ptr{sk_rect_t}, arg3::sk_path_direction_t)::Cvoid
end

function sk_path_add_circle(arg1, x, y, radius, dir)
    @ccall LibSkiaSharp.sk_path_add_circle(arg1::Ptr{sk_path_t}, x::Cfloat, y::Cfloat, radius::Cfloat, dir::sk_path_direction_t)::Cvoid
end

function sk_path_get_bounds(arg1, arg2)
    @ccall LibSkiaSharp.sk_path_get_bounds(arg1::Ptr{sk_path_t}, arg2::Ptr{sk_rect_t})::Cvoid
end

function sk_path_compute_tight_bounds(arg1, arg2)
    @ccall LibSkiaSharp.sk_path_compute_tight_bounds(arg1::Ptr{sk_path_t}, arg2::Ptr{sk_rect_t})::Cvoid
end

function sk_path_rmove_to(arg1, dx, dy)
    @ccall LibSkiaSharp.sk_path_rmove_to(arg1::Ptr{sk_path_t}, dx::Cfloat, dy::Cfloat)::Cvoid
end

function sk_path_rline_to(arg1, dx, yd)
    @ccall LibSkiaSharp.sk_path_rline_to(arg1::Ptr{sk_path_t}, dx::Cfloat, yd::Cfloat)::Cvoid
end

function sk_path_rquad_to(arg1, dx0, dy0, dx1, dy1)
    @ccall LibSkiaSharp.sk_path_rquad_to(arg1::Ptr{sk_path_t}, dx0::Cfloat, dy0::Cfloat, dx1::Cfloat, dy1::Cfloat)::Cvoid
end

function sk_path_rconic_to(arg1, dx0, dy0, dx1, dy1, w)
    @ccall LibSkiaSharp.sk_path_rconic_to(arg1::Ptr{sk_path_t}, dx0::Cfloat, dy0::Cfloat, dx1::Cfloat, dy1::Cfloat, w::Cfloat)::Cvoid
end

function sk_path_rcubic_to(arg1, dx0, dy0, dx1, dy1, dx2, dy2)
    @ccall LibSkiaSharp.sk_path_rcubic_to(arg1::Ptr{sk_path_t}, dx0::Cfloat, dy0::Cfloat, dx1::Cfloat, dy1::Cfloat, dx2::Cfloat, dy2::Cfloat)::Cvoid
end

function sk_path_add_rect_start(cpath, crect, cdir, startIndex)
    @ccall LibSkiaSharp.sk_path_add_rect_start(cpath::Ptr{sk_path_t}, crect::Ptr{sk_rect_t}, cdir::sk_path_direction_t, startIndex::UInt32)::Cvoid
end

function sk_path_add_arc(cpath, crect, startAngle, sweepAngle)
    @ccall LibSkiaSharp.sk_path_add_arc(cpath::Ptr{sk_path_t}, crect::Ptr{sk_rect_t}, startAngle::Cfloat, sweepAngle::Cfloat)::Cvoid
end

function sk_path_get_filltype(arg1)
    @ccall LibSkiaSharp.sk_path_get_filltype(arg1::Ptr{sk_path_t})::sk_path_filltype_t
end

function sk_path_set_filltype(arg1, arg2)
    @ccall LibSkiaSharp.sk_path_set_filltype(arg1::Ptr{sk_path_t}, arg2::sk_path_filltype_t)::Cvoid
end

function sk_path_transform(cpath, cmatrix)
    @ccall LibSkiaSharp.sk_path_transform(cpath::Ptr{sk_path_t}, cmatrix::Ptr{sk_matrix_t})::Cvoid
end

function sk_path_transform_to_dest(cpath, cmatrix, destination)
    @ccall LibSkiaSharp.sk_path_transform_to_dest(cpath::Ptr{sk_path_t}, cmatrix::Ptr{sk_matrix_t}, destination::Ptr{sk_path_t})::Cvoid
end

function sk_path_clone(cpath)
    @ccall LibSkiaSharp.sk_path_clone(cpath::Ptr{sk_path_t})::Ptr{sk_path_t}
end

function sk_path_add_path_offset(cpath, other, dx, dy, add_mode)
    @ccall LibSkiaSharp.sk_path_add_path_offset(cpath::Ptr{sk_path_t}, other::Ptr{sk_path_t}, dx::Cfloat, dy::Cfloat, add_mode::sk_path_add_mode_t)::Cvoid
end

function sk_path_add_path_matrix(cpath, other, matrix, add_mode)
    @ccall LibSkiaSharp.sk_path_add_path_matrix(cpath::Ptr{sk_path_t}, other::Ptr{sk_path_t}, matrix::Ptr{sk_matrix_t}, add_mode::sk_path_add_mode_t)::Cvoid
end

function sk_path_add_path(cpath, other, add_mode)
    @ccall LibSkiaSharp.sk_path_add_path(cpath::Ptr{sk_path_t}, other::Ptr{sk_path_t}, add_mode::sk_path_add_mode_t)::Cvoid
end

function sk_path_add_path_reverse(cpath, other)
    @ccall LibSkiaSharp.sk_path_add_path_reverse(cpath::Ptr{sk_path_t}, other::Ptr{sk_path_t})::Cvoid
end

function sk_path_reset(cpath)
    @ccall LibSkiaSharp.sk_path_reset(cpath::Ptr{sk_path_t})::Cvoid
end

function sk_path_rewind(cpath)
    @ccall LibSkiaSharp.sk_path_rewind(cpath::Ptr{sk_path_t})::Cvoid
end

function sk_path_count_points(cpath)
    @ccall LibSkiaSharp.sk_path_count_points(cpath::Ptr{sk_path_t})::Cint
end

function sk_path_count_verbs(cpath)
    @ccall LibSkiaSharp.sk_path_count_verbs(cpath::Ptr{sk_path_t})::Cint
end

function sk_path_get_point(cpath, index, point)
    @ccall LibSkiaSharp.sk_path_get_point(cpath::Ptr{sk_path_t}, index::Cint, point::Ptr{sk_point_t})::Cvoid
end

function sk_path_get_points(cpath, points, max)
    @ccall LibSkiaSharp.sk_path_get_points(cpath::Ptr{sk_path_t}, points::Ptr{sk_point_t}, max::Cint)::Cint
end

function sk_path_contains(cpath, x, y)
    @ccall LibSkiaSharp.sk_path_contains(cpath::Ptr{sk_path_t}, x::Cfloat, y::Cfloat)::Bool
end

function sk_path_parse_svg_string(cpath, str)
    @ccall LibSkiaSharp.sk_path_parse_svg_string(cpath::Ptr{sk_path_t}, str::Ptr{Cchar})::Bool
end

function sk_path_to_svg_string(cpath, str)
    @ccall LibSkiaSharp.sk_path_to_svg_string(cpath::Ptr{sk_path_t}, str::Ptr{sk_string_t})::Cvoid
end

function sk_path_get_last_point(cpath, point)
    @ccall LibSkiaSharp.sk_path_get_last_point(cpath::Ptr{sk_path_t}, point::Ptr{sk_point_t})::Bool
end

function sk_path_convert_conic_to_quads(p0, p1, p2, w, pts, pow2)
    @ccall LibSkiaSharp.sk_path_convert_conic_to_quads(p0::Ptr{sk_point_t}, p1::Ptr{sk_point_t}, p2::Ptr{sk_point_t}, w::Cfloat, pts::Ptr{sk_point_t}, pow2::Cint)::Cint
end

function sk_path_add_poly(cpath, points, count, close)
    @ccall LibSkiaSharp.sk_path_add_poly(cpath::Ptr{sk_path_t}, points::Ptr{sk_point_t}, count::Cint, close::Bool)::Cvoid
end

function sk_path_get_segment_masks(cpath)
    @ccall LibSkiaSharp.sk_path_get_segment_masks(cpath::Ptr{sk_path_t})::UInt32
end

function sk_path_is_oval(cpath, bounds)
    @ccall LibSkiaSharp.sk_path_is_oval(cpath::Ptr{sk_path_t}, bounds::Ptr{sk_rect_t})::Bool
end

function sk_path_is_rrect(cpath, bounds)
    @ccall LibSkiaSharp.sk_path_is_rrect(cpath::Ptr{sk_path_t}, bounds::Ptr{sk_rrect_t})::Bool
end

function sk_path_is_line(cpath, line)
    @ccall LibSkiaSharp.sk_path_is_line(cpath::Ptr{sk_path_t}, line::Ptr{sk_point_t})::Bool
end

function sk_path_is_rect(cpath, rect, isClosed, direction)
    @ccall LibSkiaSharp.sk_path_is_rect(cpath::Ptr{sk_path_t}, rect::Ptr{sk_rect_t}, isClosed::Ptr{Bool}, direction::Ptr{sk_path_direction_t})::Bool
end

function sk_path_is_convex(cpath)
    @ccall LibSkiaSharp.sk_path_is_convex(cpath::Ptr{sk_path_t})::Bool
end

function sk_path_create_iter(cpath, forceClose)
    @ccall LibSkiaSharp.sk_path_create_iter(cpath::Ptr{sk_path_t}, forceClose::Cint)::Ptr{sk_path_iterator_t}
end

function sk_path_iter_next(iterator, points)
    @ccall LibSkiaSharp.sk_path_iter_next(iterator::Ptr{sk_path_iterator_t}, points::Ptr{sk_point_t})::sk_path_verb_t
end

function sk_path_iter_conic_weight(iterator)
    @ccall LibSkiaSharp.sk_path_iter_conic_weight(iterator::Ptr{sk_path_iterator_t})::Cfloat
end

function sk_path_iter_is_close_line(iterator)
    @ccall LibSkiaSharp.sk_path_iter_is_close_line(iterator::Ptr{sk_path_iterator_t})::Cint
end

function sk_path_iter_is_closed_contour(iterator)
    @ccall LibSkiaSharp.sk_path_iter_is_closed_contour(iterator::Ptr{sk_path_iterator_t})::Cint
end

function sk_path_iter_destroy(iterator)
    @ccall LibSkiaSharp.sk_path_iter_destroy(iterator::Ptr{sk_path_iterator_t})::Cvoid
end

function sk_path_create_rawiter(cpath)
    @ccall LibSkiaSharp.sk_path_create_rawiter(cpath::Ptr{sk_path_t})::Ptr{sk_path_rawiterator_t}
end

function sk_path_rawiter_peek(iterator)
    @ccall LibSkiaSharp.sk_path_rawiter_peek(iterator::Ptr{sk_path_rawiterator_t})::sk_path_verb_t
end

function sk_path_rawiter_next(iterator, points)
    @ccall LibSkiaSharp.sk_path_rawiter_next(iterator::Ptr{sk_path_rawiterator_t}, points::Ptr{sk_point_t})::sk_path_verb_t
end

function sk_path_rawiter_conic_weight(iterator)
    @ccall LibSkiaSharp.sk_path_rawiter_conic_weight(iterator::Ptr{sk_path_rawiterator_t})::Cfloat
end

function sk_path_rawiter_destroy(iterator)
    @ccall LibSkiaSharp.sk_path_rawiter_destroy(iterator::Ptr{sk_path_rawiterator_t})::Cvoid
end

function sk_pathop_op(one, two, op, result)
    @ccall LibSkiaSharp.sk_pathop_op(one::Ptr{sk_path_t}, two::Ptr{sk_path_t}, op::sk_pathop_t, result::Ptr{sk_path_t})::Bool
end

function sk_pathop_simplify(path, result)
    @ccall LibSkiaSharp.sk_pathop_simplify(path::Ptr{sk_path_t}, result::Ptr{sk_path_t})::Bool
end

function sk_pathop_tight_bounds(path, result)
    @ccall LibSkiaSharp.sk_pathop_tight_bounds(path::Ptr{sk_path_t}, result::Ptr{sk_rect_t})::Bool
end

function sk_pathop_as_winding(path, result)
    @ccall LibSkiaSharp.sk_pathop_as_winding(path::Ptr{sk_path_t}, result::Ptr{sk_path_t})::Bool
end

function sk_opbuilder_new()
    @ccall LibSkiaSharp.sk_opbuilder_new()::Ptr{sk_opbuilder_t}
end

function sk_opbuilder_destroy(builder)
    @ccall LibSkiaSharp.sk_opbuilder_destroy(builder::Ptr{sk_opbuilder_t})::Cvoid
end

function sk_opbuilder_add(builder, path, op)
    @ccall LibSkiaSharp.sk_opbuilder_add(builder::Ptr{sk_opbuilder_t}, path::Ptr{sk_path_t}, op::sk_pathop_t)::Cvoid
end

function sk_opbuilder_resolve(builder, result)
    @ccall LibSkiaSharp.sk_opbuilder_resolve(builder::Ptr{sk_opbuilder_t}, result::Ptr{sk_path_t})::Bool
end

function sk_pathmeasure_new()
    @ccall LibSkiaSharp.sk_pathmeasure_new()::Ptr{sk_pathmeasure_t}
end

function sk_pathmeasure_new_with_path(path, forceClosed, resScale)
    @ccall LibSkiaSharp.sk_pathmeasure_new_with_path(path::Ptr{sk_path_t}, forceClosed::Bool, resScale::Cfloat)::Ptr{sk_pathmeasure_t}
end

function sk_pathmeasure_destroy(pathMeasure)
    @ccall LibSkiaSharp.sk_pathmeasure_destroy(pathMeasure::Ptr{sk_pathmeasure_t})::Cvoid
end

function sk_pathmeasure_set_path(pathMeasure, path, forceClosed)
    @ccall LibSkiaSharp.sk_pathmeasure_set_path(pathMeasure::Ptr{sk_pathmeasure_t}, path::Ptr{sk_path_t}, forceClosed::Bool)::Cvoid
end

function sk_pathmeasure_get_length(pathMeasure)
    @ccall LibSkiaSharp.sk_pathmeasure_get_length(pathMeasure::Ptr{sk_pathmeasure_t})::Cfloat
end

function sk_pathmeasure_get_pos_tan(pathMeasure, distance, position, tangent)
    @ccall LibSkiaSharp.sk_pathmeasure_get_pos_tan(pathMeasure::Ptr{sk_pathmeasure_t}, distance::Cfloat, position::Ptr{sk_point_t}, tangent::Ptr{sk_vector_t})::Bool
end

function sk_pathmeasure_get_matrix(pathMeasure, distance, matrix, flags)
    @ccall LibSkiaSharp.sk_pathmeasure_get_matrix(pathMeasure::Ptr{sk_pathmeasure_t}, distance::Cfloat, matrix::Ptr{sk_matrix_t}, flags::sk_pathmeasure_matrixflags_t)::Bool
end

function sk_pathmeasure_get_segment(pathMeasure, start, stop, dst, startWithMoveTo)
    @ccall LibSkiaSharp.sk_pathmeasure_get_segment(pathMeasure::Ptr{sk_pathmeasure_t}, start::Cfloat, stop::Cfloat, dst::Ptr{sk_path_t}, startWithMoveTo::Bool)::Bool
end

function sk_pathmeasure_is_closed(pathMeasure)
    @ccall LibSkiaSharp.sk_pathmeasure_is_closed(pathMeasure::Ptr{sk_pathmeasure_t})::Bool
end

function sk_pathmeasure_next_contour(pathMeasure)
    @ccall LibSkiaSharp.sk_pathmeasure_next_contour(pathMeasure::Ptr{sk_pathmeasure_t})::Bool
end

function sk_typeface_unref(typeface)
    @ccall LibSkiaSharp.sk_typeface_unref(typeface::Ptr{sk_typeface_t})::Cvoid
end

function sk_typeface_get_fontstyle(typeface)
    @ccall LibSkiaSharp.sk_typeface_get_fontstyle(typeface::Ptr{sk_typeface_t})::Ptr{sk_fontstyle_t}
end

function sk_typeface_get_font_weight(typeface)
    @ccall LibSkiaSharp.sk_typeface_get_font_weight(typeface::Ptr{sk_typeface_t})::Cint
end

function sk_typeface_get_font_width(typeface)
    @ccall LibSkiaSharp.sk_typeface_get_font_width(typeface::Ptr{sk_typeface_t})::Cint
end

function sk_typeface_get_font_slant(typeface)
    @ccall LibSkiaSharp.sk_typeface_get_font_slant(typeface::Ptr{sk_typeface_t})::sk_font_style_slant_t
end

function sk_typeface_is_fixed_pitch(typeface)
    @ccall LibSkiaSharp.sk_typeface_is_fixed_pitch(typeface::Ptr{sk_typeface_t})::Bool
end

function sk_typeface_create_default()
    @ccall LibSkiaSharp.sk_typeface_create_default()::Ptr{sk_typeface_t}
end

function sk_typeface_ref_default()
    @ccall LibSkiaSharp.sk_typeface_ref_default()::Ptr{sk_typeface_t}
end

function sk_typeface_create_from_name(familyName, style)
    @ccall LibSkiaSharp.sk_typeface_create_from_name(familyName::Ptr{Cchar}, style::Ptr{sk_fontstyle_t})::Ptr{sk_typeface_t}
end

function sk_typeface_create_from_file(path, index)
    @ccall LibSkiaSharp.sk_typeface_create_from_file(path::Ptr{Cchar}, index::Cint)::Ptr{sk_typeface_t}
end

function sk_typeface_create_from_stream(stream, index)
    @ccall LibSkiaSharp.sk_typeface_create_from_stream(stream::Ptr{sk_stream_asset_t}, index::Cint)::Ptr{sk_typeface_t}
end

function sk_typeface_create_from_data(data, index)
    @ccall LibSkiaSharp.sk_typeface_create_from_data(data::Ptr{sk_data_t}, index::Cint)::Ptr{sk_typeface_t}
end

function sk_typeface_unichars_to_glyphs(typeface, unichars, count, glyphs)
    @ccall LibSkiaSharp.sk_typeface_unichars_to_glyphs(typeface::Ptr{sk_typeface_t}, unichars::Ptr{Int32}, count::Cint, glyphs::Ptr{UInt16})::Cvoid
end

function sk_typeface_unichar_to_glyph(typeface, unichar)
    @ccall LibSkiaSharp.sk_typeface_unichar_to_glyph(typeface::Ptr{sk_typeface_t}, unichar::Int32)::UInt16
end

function sk_typeface_count_glyphs(typeface)
    @ccall LibSkiaSharp.sk_typeface_count_glyphs(typeface::Ptr{sk_typeface_t})::Cint
end

function sk_typeface_count_tables(typeface)
    @ccall LibSkiaSharp.sk_typeface_count_tables(typeface::Ptr{sk_typeface_t})::Cint
end

function sk_typeface_get_table_tags(typeface, tags)
    @ccall LibSkiaSharp.sk_typeface_get_table_tags(typeface::Ptr{sk_typeface_t}, tags::Ptr{sk_font_table_tag_t})::Cint
end

function sk_typeface_get_table_size(typeface, tag)
    @ccall LibSkiaSharp.sk_typeface_get_table_size(typeface::Ptr{sk_typeface_t}, tag::sk_font_table_tag_t)::Csize_t
end

function sk_typeface_get_table_data(typeface, tag, offset, length, data)
    @ccall LibSkiaSharp.sk_typeface_get_table_data(typeface::Ptr{sk_typeface_t}, tag::sk_font_table_tag_t, offset::Csize_t, length::Csize_t, data::Ptr{Cvoid})::Csize_t
end

function sk_typeface_copy_table_data(typeface, tag)
    @ccall LibSkiaSharp.sk_typeface_copy_table_data(typeface::Ptr{sk_typeface_t}, tag::sk_font_table_tag_t)::Ptr{sk_data_t}
end

function sk_typeface_get_units_per_em(typeface)
    @ccall LibSkiaSharp.sk_typeface_get_units_per_em(typeface::Ptr{sk_typeface_t})::Cint
end

function sk_typeface_get_kerning_pair_adjustments(typeface, glyphs, count, adjustments)
    @ccall LibSkiaSharp.sk_typeface_get_kerning_pair_adjustments(typeface::Ptr{sk_typeface_t}, glyphs::Ptr{UInt16}, count::Cint, adjustments::Ptr{Int32})::Bool
end

function sk_typeface_get_family_name(typeface)
    @ccall LibSkiaSharp.sk_typeface_get_family_name(typeface::Ptr{sk_typeface_t})::Ptr{sk_string_t}
end

function sk_typeface_open_stream(typeface, ttcIndex)
    @ccall LibSkiaSharp.sk_typeface_open_stream(typeface::Ptr{sk_typeface_t}, ttcIndex::Ptr{Cint})::Ptr{sk_stream_asset_t}
end

function sk_fontmgr_create_default()
    @ccall LibSkiaSharp.sk_fontmgr_create_default()::Ptr{sk_fontmgr_t}
end

function sk_fontmgr_ref_default()
    @ccall LibSkiaSharp.sk_fontmgr_ref_default()::Ptr{sk_fontmgr_t}
end

function sk_fontmgr_unref(arg1)
    @ccall LibSkiaSharp.sk_fontmgr_unref(arg1::Ptr{sk_fontmgr_t})::Cvoid
end

function sk_fontmgr_count_families(arg1)
    @ccall LibSkiaSharp.sk_fontmgr_count_families(arg1::Ptr{sk_fontmgr_t})::Cint
end

function sk_fontmgr_get_family_name(arg1, index, familyName)
    @ccall LibSkiaSharp.sk_fontmgr_get_family_name(arg1::Ptr{sk_fontmgr_t}, index::Cint, familyName::Ptr{sk_string_t})::Cvoid
end

function sk_fontmgr_create_styleset(arg1, index)
    @ccall LibSkiaSharp.sk_fontmgr_create_styleset(arg1::Ptr{sk_fontmgr_t}, index::Cint)::Ptr{sk_fontstyleset_t}
end

function sk_fontmgr_match_family(arg1, familyName)
    @ccall LibSkiaSharp.sk_fontmgr_match_family(arg1::Ptr{sk_fontmgr_t}, familyName::Ptr{Cchar})::Ptr{sk_fontstyleset_t}
end

function sk_fontmgr_match_family_style(arg1, familyName, style)
    @ccall LibSkiaSharp.sk_fontmgr_match_family_style(arg1::Ptr{sk_fontmgr_t}, familyName::Ptr{Cchar}, style::Ptr{sk_fontstyle_t})::Ptr{sk_typeface_t}
end

function sk_fontmgr_match_family_style_character(arg1, familyName, style, bcp47, bcp47Count, character)
    @ccall LibSkiaSharp.sk_fontmgr_match_family_style_character(arg1::Ptr{sk_fontmgr_t}, familyName::Ptr{Cchar}, style::Ptr{sk_fontstyle_t}, bcp47::Ptr{Ptr{Cchar}}, bcp47Count::Cint, character::Int32)::Ptr{sk_typeface_t}
end

function sk_fontmgr_create_from_data(arg1, data, index)
    @ccall LibSkiaSharp.sk_fontmgr_create_from_data(arg1::Ptr{sk_fontmgr_t}, data::Ptr{sk_data_t}, index::Cint)::Ptr{sk_typeface_t}
end

function sk_fontmgr_create_from_stream(arg1, stream, index)
    @ccall LibSkiaSharp.sk_fontmgr_create_from_stream(arg1::Ptr{sk_fontmgr_t}, stream::Ptr{sk_stream_asset_t}, index::Cint)::Ptr{sk_typeface_t}
end

function sk_fontmgr_create_from_file(arg1, path, index)
    @ccall LibSkiaSharp.sk_fontmgr_create_from_file(arg1::Ptr{sk_fontmgr_t}, path::Ptr{Cchar}, index::Cint)::Ptr{sk_typeface_t}
end

function sk_fontstyle_new(weight, width, slant)
    @ccall LibSkiaSharp.sk_fontstyle_new(weight::Cint, width::Cint, slant::sk_font_style_slant_t)::Ptr{sk_fontstyle_t}
end

function sk_fontstyle_delete(fs)
    @ccall LibSkiaSharp.sk_fontstyle_delete(fs::Ptr{sk_fontstyle_t})::Cvoid
end

function sk_fontstyle_get_weight(fs)
    @ccall LibSkiaSharp.sk_fontstyle_get_weight(fs::Ptr{sk_fontstyle_t})::Cint
end

function sk_fontstyle_get_width(fs)
    @ccall LibSkiaSharp.sk_fontstyle_get_width(fs::Ptr{sk_fontstyle_t})::Cint
end

function sk_fontstyle_get_slant(fs)
    @ccall LibSkiaSharp.sk_fontstyle_get_slant(fs::Ptr{sk_fontstyle_t})::sk_font_style_slant_t
end

function sk_fontstyleset_create_empty()
    @ccall LibSkiaSharp.sk_fontstyleset_create_empty()::Ptr{sk_fontstyleset_t}
end

function sk_fontstyleset_unref(fss)
    @ccall LibSkiaSharp.sk_fontstyleset_unref(fss::Ptr{sk_fontstyleset_t})::Cvoid
end

function sk_fontstyleset_get_count(fss)
    @ccall LibSkiaSharp.sk_fontstyleset_get_count(fss::Ptr{sk_fontstyleset_t})::Cint
end

function sk_fontstyleset_get_style(fss, index, fs, style)
    @ccall LibSkiaSharp.sk_fontstyleset_get_style(fss::Ptr{sk_fontstyleset_t}, index::Cint, fs::Ptr{sk_fontstyle_t}, style::Ptr{sk_string_t})::Cvoid
end

function sk_fontstyleset_create_typeface(fss, index)
    @ccall LibSkiaSharp.sk_fontstyleset_create_typeface(fss::Ptr{sk_fontstyleset_t}, index::Cint)::Ptr{sk_typeface_t}
end

function sk_fontstyleset_match_style(fss, style)
    @ccall LibSkiaSharp.sk_fontstyleset_match_style(fss::Ptr{sk_fontstyleset_t}, style::Ptr{sk_fontstyle_t})::Ptr{sk_typeface_t}
end

function sk_font_new()
    @ccall LibSkiaSharp.sk_font_new()::Ptr{sk_font_t}
end

function sk_font_new_with_values(typeface, size, scaleX, skewX)
    @ccall LibSkiaSharp.sk_font_new_with_values(typeface::Ptr{sk_typeface_t}, size::Cfloat, scaleX::Cfloat, skewX::Cfloat)::Ptr{sk_font_t}
end

function sk_font_delete(font)
    @ccall LibSkiaSharp.sk_font_delete(font::Ptr{sk_font_t})::Cvoid
end

function sk_font_is_force_auto_hinting(font)
    @ccall LibSkiaSharp.sk_font_is_force_auto_hinting(font::Ptr{sk_font_t})::Bool
end

function sk_font_set_force_auto_hinting(font, value)
    @ccall LibSkiaSharp.sk_font_set_force_auto_hinting(font::Ptr{sk_font_t}, value::Bool)::Cvoid
end

function sk_font_is_embedded_bitmaps(font)
    @ccall LibSkiaSharp.sk_font_is_embedded_bitmaps(font::Ptr{sk_font_t})::Bool
end

function sk_font_set_embedded_bitmaps(font, value)
    @ccall LibSkiaSharp.sk_font_set_embedded_bitmaps(font::Ptr{sk_font_t}, value::Bool)::Cvoid
end

function sk_font_is_subpixel(font)
    @ccall LibSkiaSharp.sk_font_is_subpixel(font::Ptr{sk_font_t})::Bool
end

function sk_font_set_subpixel(font, value)
    @ccall LibSkiaSharp.sk_font_set_subpixel(font::Ptr{sk_font_t}, value::Bool)::Cvoid
end

function sk_font_is_linear_metrics(font)
    @ccall LibSkiaSharp.sk_font_is_linear_metrics(font::Ptr{sk_font_t})::Bool
end

function sk_font_set_linear_metrics(font, value)
    @ccall LibSkiaSharp.sk_font_set_linear_metrics(font::Ptr{sk_font_t}, value::Bool)::Cvoid
end

function sk_font_is_embolden(font)
    @ccall LibSkiaSharp.sk_font_is_embolden(font::Ptr{sk_font_t})::Bool
end

function sk_font_set_embolden(font, value)
    @ccall LibSkiaSharp.sk_font_set_embolden(font::Ptr{sk_font_t}, value::Bool)::Cvoid
end

function sk_font_is_baseline_snap(font)
    @ccall LibSkiaSharp.sk_font_is_baseline_snap(font::Ptr{sk_font_t})::Bool
end

function sk_font_set_baseline_snap(font, value)
    @ccall LibSkiaSharp.sk_font_set_baseline_snap(font::Ptr{sk_font_t}, value::Bool)::Cvoid
end

function sk_font_get_edging(font)
    @ccall LibSkiaSharp.sk_font_get_edging(font::Ptr{sk_font_t})::sk_font_edging_t
end

function sk_font_set_edging(font, value)
    @ccall LibSkiaSharp.sk_font_set_edging(font::Ptr{sk_font_t}, value::sk_font_edging_t)::Cvoid
end

function sk_font_get_hinting(font)
    @ccall LibSkiaSharp.sk_font_get_hinting(font::Ptr{sk_font_t})::sk_font_hinting_t
end

function sk_font_set_hinting(font, value)
    @ccall LibSkiaSharp.sk_font_set_hinting(font::Ptr{sk_font_t}, value::sk_font_hinting_t)::Cvoid
end

function sk_font_get_typeface(font)
    @ccall LibSkiaSharp.sk_font_get_typeface(font::Ptr{sk_font_t})::Ptr{sk_typeface_t}
end

function sk_font_set_typeface(font, value)
    @ccall LibSkiaSharp.sk_font_set_typeface(font::Ptr{sk_font_t}, value::Ptr{sk_typeface_t})::Cvoid
end

function sk_font_get_size(font)
    @ccall LibSkiaSharp.sk_font_get_size(font::Ptr{sk_font_t})::Cfloat
end

function sk_font_set_size(font, value)
    @ccall LibSkiaSharp.sk_font_set_size(font::Ptr{sk_font_t}, value::Cfloat)::Cvoid
end

function sk_font_get_scale_x(font)
    @ccall LibSkiaSharp.sk_font_get_scale_x(font::Ptr{sk_font_t})::Cfloat
end

function sk_font_set_scale_x(font, value)
    @ccall LibSkiaSharp.sk_font_set_scale_x(font::Ptr{sk_font_t}, value::Cfloat)::Cvoid
end

function sk_font_get_skew_x(font)
    @ccall LibSkiaSharp.sk_font_get_skew_x(font::Ptr{sk_font_t})::Cfloat
end

function sk_font_set_skew_x(font, value)
    @ccall LibSkiaSharp.sk_font_set_skew_x(font::Ptr{sk_font_t}, value::Cfloat)::Cvoid
end

function sk_font_text_to_glyphs(font, text, byteLength, encoding, glyphs, maxGlyphCount)
    @ccall LibSkiaSharp.sk_font_text_to_glyphs(font::Ptr{sk_font_t}, text::Ptr{Cvoid}, byteLength::Csize_t, encoding::sk_text_encoding_t, glyphs::Ptr{UInt16}, maxGlyphCount::Cint)::Cint
end

function sk_font_unichar_to_glyph(font, uni)
    @ccall LibSkiaSharp.sk_font_unichar_to_glyph(font::Ptr{sk_font_t}, uni::Int32)::UInt16
end

function sk_font_unichars_to_glyphs(font, uni, count, glyphs)
    @ccall LibSkiaSharp.sk_font_unichars_to_glyphs(font::Ptr{sk_font_t}, uni::Ptr{Int32}, count::Cint, glyphs::Ptr{UInt16})::Cvoid
end

function sk_font_measure_text(font, text, byteLength, encoding, bounds, paint)
    @ccall LibSkiaSharp.sk_font_measure_text(font::Ptr{sk_font_t}, text::Ptr{Cvoid}, byteLength::Csize_t, encoding::sk_text_encoding_t, bounds::Ptr{sk_rect_t}, paint::Ptr{sk_paint_t})::Cfloat
end

function sk_font_measure_text_no_return(font, text, byteLength, encoding, bounds, paint, measuredWidth)
    @ccall LibSkiaSharp.sk_font_measure_text_no_return(font::Ptr{sk_font_t}, text::Ptr{Cvoid}, byteLength::Csize_t, encoding::sk_text_encoding_t, bounds::Ptr{sk_rect_t}, paint::Ptr{sk_paint_t}, measuredWidth::Ptr{Cfloat})::Cvoid
end

function sk_font_break_text(font, text, byteLength, encoding, maxWidth, measuredWidth, paint)
    @ccall LibSkiaSharp.sk_font_break_text(font::Ptr{sk_font_t}, text::Ptr{Cvoid}, byteLength::Csize_t, encoding::sk_text_encoding_t, maxWidth::Cfloat, measuredWidth::Ptr{Cfloat}, paint::Ptr{sk_paint_t})::Csize_t
end

function sk_font_get_widths_bounds(font, glyphs, count, widths, bounds, paint)
    @ccall LibSkiaSharp.sk_font_get_widths_bounds(font::Ptr{sk_font_t}, glyphs::Ptr{UInt16}, count::Cint, widths::Ptr{Cfloat}, bounds::Ptr{sk_rect_t}, paint::Ptr{sk_paint_t})::Cvoid
end

function sk_font_get_pos(font, glyphs, count, pos, origin)
    @ccall LibSkiaSharp.sk_font_get_pos(font::Ptr{sk_font_t}, glyphs::Ptr{UInt16}, count::Cint, pos::Ptr{sk_point_t}, origin::Ptr{sk_point_t})::Cvoid
end

function sk_font_get_xpos(font, glyphs, count, xpos, origin)
    @ccall LibSkiaSharp.sk_font_get_xpos(font::Ptr{sk_font_t}, glyphs::Ptr{UInt16}, count::Cint, xpos::Ptr{Cfloat}, origin::Cfloat)::Cvoid
end

function sk_font_get_path(font, glyph, path)
    @ccall LibSkiaSharp.sk_font_get_path(font::Ptr{sk_font_t}, glyph::UInt16, path::Ptr{sk_path_t})::Bool
end

function sk_font_get_paths(font, glyphs, count, glyphPathProc, context)
    @ccall LibSkiaSharp.sk_font_get_paths(font::Ptr{sk_font_t}, glyphs::Ptr{UInt16}, count::Cint, glyphPathProc::sk_glyph_path_proc, context::Ptr{Cvoid})::Cvoid
end

function sk_font_get_metrics(font, metrics)
    @ccall LibSkiaSharp.sk_font_get_metrics(font::Ptr{sk_font_t}, metrics::Ptr{sk_fontmetrics_t})::Cfloat
end

function sk_text_utils_get_path(text, length, encoding, x, y, font, path)
    @ccall LibSkiaSharp.sk_text_utils_get_path(text::Ptr{Cvoid}, length::Csize_t, encoding::sk_text_encoding_t, x::Cfloat, y::Cfloat, font::Ptr{sk_font_t}, path::Ptr{sk_path_t})::Cvoid
end

function sk_text_utils_get_pos_path(text, length, encoding, pos, font, path)
    @ccall LibSkiaSharp.sk_text_utils_get_pos_path(text::Ptr{Cvoid}, length::Csize_t, encoding::sk_text_encoding_t, pos::Ptr{sk_point_t}, font::Ptr{sk_font_t}, path::Ptr{sk_path_t})::Cvoid
end

const SK_C_INCREMENT = 0

const FONTMETRICS_FLAGS_UNDERLINE_THICKNESS_IS_VALID = Cuint(1) << 0

const FONTMETRICS_FLAGS_UNDERLINE_POSITION_IS_VALID = Cuint(1) << 1

# Skipping MacroDefinition: gr_mtl_handle_t const void *

# Export all
for name in names(@__MODULE__; all=true)
    if name in [:eval, :include, Symbol("#eval"), Symbol("#include")]; continue end
    @eval export $name
end

end # module
