
; Union type
; i32        - int
; i8*        - symbol
; i1         - nil
; i1         - true/false
; i8*        - string
; %Mal.Type* - list
%Mal.Data = type { i64 }

%Mal.Type = type {
  %Mal.Data, ; data
  i8         ; type
}

; types
; 0 - int
; 1 - symbol
; 2 - nil
; 3 - true/false
; 4 - string
; 5 - list

; TODO: improve list implementation
define %Mal.Type @Mal.List.Init() {
  ret %Mal.Type null
}

