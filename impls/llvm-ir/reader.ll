
; token vector
@tokens = private alloca i8**

define i8* @Peek() {

  ; global load
  %tokens = load i8**, i8*** @tokens

  ; pointer arithmetic to get offset 1
  ; %1 = getelementptr inbounds i8*, i8** %tokens, i64 1

  %next = load i8*, i8** %tokens

  ret i8* %next
}

