open Async
open Core

type 'a parser = Yojson.Safe.t -> 'a Ppx_deriving_yojson_runtime.error_or

let query ?executable ~parse q =
  let open Deferred.Or_error.Let_syntax in
  let prog =
    Option.merge executable (Sys.getenv "CQLSH") ~f:Fn.const
    |> Option.value ~default:"cqlsh"
  in
  printf "SQL: '%s'\n" q ;
  let%bind data = Process.run_lines ~prog ~stdin:q ~args:[] () in
  List.slice data 3 (-2) (* skip header and footer *)
  |> List.filter ~f:(fun s -> not (String.is_empty s))
  |> List.fold_right ~init:(Ok []) ~f:(fun line acc ->
         let open Or_error.Let_syntax in
         let%bind l = acc in
         try
           let j = Yojson.Safe.from_string line in
           match parse j with
           | Ppx_deriving_yojson_runtime.Result.Ok s ->
               Ok (s :: l)
           | Ppx_deriving_yojson_runtime.Result.Error e ->
               Or_error.error_string e
         with Yojson.Json_error e -> Or_error.error_string e )
  |> Deferred.return

let select ?executable ~keyspace ~parse ~fields ?where from =
  query ?executable ~parse
  @@ Printf.sprintf "SELECT JSON %s FROM %s.%s%s;"
       (String.concat ~sep:"," fields)
       keyspace from
       (match where with None -> "" | Some w -> " WHERE " ^ w)
