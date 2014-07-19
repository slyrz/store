#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/fail.h>

#include <libavformat/avformat.h>
#include <libavutil/avutil.h>
#include <libavutil/dict.h>

#include <ft2build.h>
#include <freetype.h>

#define either(s,v) (((s) != NULL) ? (s) : (v))

#define copy_tag(tag,dst) \
  do { \
    if (strcasecmp ((tag)->key, #dst) == 0) \
      (dst) = (tag)->value; \
  } while (0)

#define store_string_copy(dst,idx,var) \
  do { \
    Store_field ((dst), (idx), caml_copy_string (either ((var), ""))); \
  } while (0)

static FT_Library
library;

static int
initialized = 0;

void
meta_init (void)
{
  CAMLparam0 ();

  if (initialized)
    return;

  if (FT_Init_FreeType (&library) != 0)
    caml_failwith ("FT_Init_FreeType");

  av_register_all ();
  av_log_set_level (AV_LOG_ERROR);

  initialized = 1;
  CAMLnoreturn;
}

void
meta_free (void)
{
  CAMLparam0 ();

  if (!initialized)
    return;

  if (FT_Done_FreeType (library) != 0)
    caml_failwith ("FT_Done_Free");

  initialized = 0;
  CAMLnoreturn;
}

CAMLprim value
meta_get_font_info (value path)
{
  CAMLparam1 (path);
  CAMLlocal1 (result);

  FT_Face face;

  if (!initialized)
    caml_failwith ("not initialized");

  if (FT_New_Face (library, String_val (path), 0, &face) != 0)
    caml_failwith ("FT_New_Face");

  result = caml_alloc (2, 0);
  store_string_copy (result, 0, face->family_name);
  store_string_copy (result, 1, face->style_name);
  FT_Done_Face (face);
  CAMLreturn (result);
}

CAMLprim value
meta_get_music_info (value path)
{
  CAMLparam1 (path);
  CAMLlocal1 (result);

  AVFormatContext *fmt = NULL;
  AVDictionaryEntry *tag = NULL;

  if (avformat_open_input (&fmt, String_val (path), NULL, NULL) < 0)
    caml_failwith ("avformat_open_input");

  char *album = NULL;
  char *artist = NULL;
  char *title = NULL;
  char *track = NULL;

  while ((tag = av_dict_get (fmt->metadata, "", tag, AV_DICT_IGNORE_SUFFIX))) {
    copy_tag (tag, artist);
    copy_tag (tag, album);
    copy_tag (tag, track);
    copy_tag (tag, title);
  }

  if (!(album && artist && title && track))
    caml_failwith ("not all metadata found");

  result = caml_alloc (4, 0);
  store_string_copy (result, 0, artist);
  store_string_copy (result, 1, album);
  store_string_copy (result, 2, track);
  store_string_copy (result, 3, title);
  avformat_close_input (&fmt);
  CAMLreturn (result);
}
