open Async
open Mina_base

type t =
  { created_at : string
  ; submitter : string
  ; state_hash : State_hash.t
  ; parent : State_hash.t
  ; height : Unsigned.uint32
  ; slot : Mina_numbers.Global_slot_since_genesis.t
  }

let valid_payload_to_yojson (p : t) : Yojson.Safe.t =
  `Assoc
    [ ("created_at", `String p.created_at)
    ; ("submitter", `String p.submitter)
    ; ("state_hash", State_hash.to_yojson p.state_hash)
    ; ("parent", State_hash.to_yojson p.parent)
    ; ("height", `Int (Unsigned.UInt32.to_int p.height))
    ; ("slot", `Int (Mina_numbers.Global_slot_since_genesis.to_int p.slot))
    ]

let display valid_payload =
  printf "%s\n" @@ Yojson.Safe.to_string
  @@ valid_payload_to_yojson valid_payload

let display_error e =
  eprintf "%s\n" @@ Yojson.Safe.to_string @@ `Assoc [ ("error", `String e) ]
