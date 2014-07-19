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
      String.sub str pos (len-pos)
  with
  | Not_found -> ""
;;

(* Create a directory and make parent directories as needed. *)
let mkdir path =
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

(* Used to match the first number in a string. *)
let regex = Str.regexp "\\([0-9]+\\)"

(* Convert a track string ("1" or something like "1/13") to int. *)
let int_of_track track =
  if (Str.string_match regex track 0) then
    Str.matched_group 0 track |> int_of_string
  else
    failwith "not a number"
;;

let test_font_file path =
  extension path =>> [ ".ttf"; ".otf"; ]
;;

let name_font_file path =
  let title_join str =
    split str ' ' |> List.map String.capitalize |> String.concat ""
  in
  let inf = Meta.font_info path in
  let ext = extension path in
    home </> ".fonts" </> inf.Meta.family </> (Printf.sprintf "%s-%s%s" (title_join inf.Meta.family) (title_join inf.Meta.style) ext)
;;

let test_music_file path =
  extension path =>> [ ".mp3"; ".wma"; ".m4a"; ".flac"; ".ogg"; ".wav"; ]
;;

let name_music_file path =
  let inf = Meta.music_info path in
  let ext = extension path in
    home </> "Music" </> inf.Meta.artist </> inf.Meta.album </> (Printf.sprintf "%02d %s%s" (int_of_track inf.Meta.track) inf.Meta.title ext)
;;

let pretend = ref false

(* Command line options. *)
let speclist =
  [
    ("-pretend", Arg.Set pretend, "Don't perform any changes");
  ]

(* Supported file types. *)
let renamers =
  [
    (test_font_file, name_font_file);
    (test_music_file, name_music_file);
  ]

let perform_rename old_name new_name =
  Printf.printf "%s -> %s\n" old_name new_name
  (* TODO *)
;;

let rename path =
  let rec rename path renamers =
    match renamers with
    | (test,name)::tail -> if test path
      then name path |> perform_rename path
      else rename path tail
    | [] -> ()
  in
    rename path renamers
;;

let main () =
  Arg.parse speclist rename "store [-pretend|help]... FILE...";
;;

main ();
