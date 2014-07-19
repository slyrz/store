type font_meta =
  {
    family : string;
    style  : string;
  }
;;

type music_meta =
  {
    artist : string;
    album  : string;
    track  : string;
    title  : string;
  }
;;

module Lib =
  struct
    external init : unit -> unit = "meta_init"
    external free : unit -> unit = "meta_free"
    external font_info  : string -> font_meta  = "meta_get_font_info"
    external music_info : string -> music_meta = "meta_get_music_info"
  end
;;

let initialized = ref false

let ensure_init f =
  if not !initialized then
  begin
    Lib.init (); initialized := true;
  end;
  f
;;

let font_info = ensure_init Lib.font_info
let music_info = ensure_init Lib.music_info
