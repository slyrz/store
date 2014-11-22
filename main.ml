let (=>>) = List.mem
let (</>) = Filename.concat

(* Convert a string to a list of chars. *)
let explode s =
  let rec exp i l =
    if i < 0 then l else exp (i - 1) (s.[i] :: l) in
  exp (String.length s - 1) []

(* Convert a list of chars to string. *)
let implode l =
  let rec imp i s = function
    | [] -> s
    | chr :: rem -> s.[i] <- chr; imp (i+1) s rem
  in
  let n = List.length l in
    imp 0 (String.create n) l
;;

(* Split a string at every occurrence of the delimiter char. *)
let split str delim =
  let rec split delim word words = function
    | [] -> words @ [word]
    | chr :: rem -> if chr = delim
      then split delim [] (words @ [word]) rem
      else split delim (word @ [chr]) words rem
  in
    explode str |> split delim [] []  |> List.filter ((<>) []) |> List.map implode
;;

(* Return the path of the home folder. *)
let home = Unix.getuid () |> Unix.getpwuid |> (fun x -> x.Unix.pw_dir)

(* Return the filename extension. *)
let extension str =
  try
    let len = String.length str in
    let pos = String.rindex str '.' in
      String.sub str pos (len-pos) |> String.lowercase
  with
  | Not_found -> ""
;;

(* List all paths in a directory. *)
let list_path path =
  let readdir dir = Sys.readdir dir |> Array.to_list |> List.map (Filename.concat dir) in
  let rec list_path = function
    | path::tail -> (if Sys.is_directory path then readdir path |> list_path else [path]) @ (list_path tail)
    | [] -> []
  in
    list_path [path]
;;

(* Create a directory and make parent directories as needed. *)
let make_path path =
  let rec ascend base = function
    | head::tail ->
        let part = Filename.concat base head in
          if not (Sys.file_exists part) then
            Unix.mkdir part 0o777;
          ascend part tail
    | [] -> ()
  in
  let base = if Filename.is_relative path then "" else "/" in
    split path '/' |> ascend base
;;

(* Used to match the first number in a string. *)
let regex = Str.regexp "\\([0-9]+\\)"

(* Convert a track string ("1" or something like "1/13") to int. *)
let int_of_track track =
  if (Str.string_match regex track 0) then
    Str.matched_group 0 track |> int_of_string
  else
    failwith "not a number"
;;

(* Remove '/' from filenames. *)
let sanitize filename =
  Str.global_replace (Str.regexp "\ */\ *") " - " filename
;;

(* Variables set by command line flags. *)
let font_directory = ref (home </> ".fonts")
let music_directory = ref (home </> "Music")
let pretend = ref false

let test_font_file path =
  extension path =>> [ ".ttf"; ".otf"; ]
;;

let name_font_file path =
  let title_join str =
    split str ' ' |> List.map String.capitalize |> String.concat ""
  in
  let inf = Meta.font_info path in
  let ext = extension path in
  let filepath = !font_directory </> inf.Meta.family in
  let filename = Printf.sprintf "%s-%s%s" (title_join inf.Meta.family) (title_join inf.Meta.style) ext in
    filepath </> (sanitize filename)
;;

let test_music_file path =
  extension path =>> [ ".mp3"; ".wma"; ".m4a"; ".flac"; ".ogg"; ".wav"; ]
;;

let name_music_file path =
  let inf = Meta.music_info path in
  let ext = extension path in
  let filepath = !music_directory </> inf.Meta.artist </> inf.Meta.album in
  let filename = Printf.sprintf "%02d %s%s" (int_of_track inf.Meta.track) inf.Meta.title ext in
    filepath </> (sanitize filename)
;;

(* Command line options. *)
let speclist =
  [
    ("-font-directory", Arg.Set_string font_directory, "Target directory for font files.");
    ("-music-directory", Arg.Set_string music_directory, "Target directory for music files.");
    ("-pretend", Arg.Set pretend, "Don't perform any changes");
  ]

(* Supported file types. *)
let renamers =
  [
    (test_font_file, name_font_file);
    (test_music_file, name_music_file);
  ]

(* Returns a tuple of (old name, new name) strings. *)
let get_change path =
  let rec rename path = function
    | (test,name)::tail -> if test path
      then (path, name path)
      else rename path tail
    | [] -> (path, path)
  in
    rename path renamers
;;

(* Handles all command line arguments. *)
let handle_argument path =
  (* Make sure we don't override existing files. *)
  let validate (src,dst) =
    Printf.printf ">>> %s -> %s\n" src dst;
    if (Sys.file_exists dst) then
      failwith (dst ^ " exists.");
  in
  (* Move src to dst and create directories as needed. *)
  let perform (src,dst) =
    Filename.dirname dst |> make_path;
    Sys.rename src dst;
  in
  (* Used to ignore already correctly named files. *)
  let name_changes = function
    | (src,dst) -> src<>dst
  in
  let changes = list_path path |> List.map get_change |> List.filter name_changes in
    List.iter validate changes;
    if not (!pretend) then
      List.iter perform changes;
;;

let main () =
  Arg.parse speclist handle_argument "store [OPTION]... PATH...";
;;

main ();
