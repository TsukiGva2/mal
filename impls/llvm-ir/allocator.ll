@ALLOC_ERR = constant [17 x i8] c"Allocation error\00"

%LL = type {
  i8*,
  %LL*
}

define void @IsValidPtr(i8* %ptr) {

  %isNull = icmp eq i8* %ptr, null
  br i1 %isNull, label %die, label %ok

die:
  call void
    @Die(i8* getelementptr (
      [17 x i8],
      [17 x i8]* @ALLOC_ERR,
      i64 0,
      i64 0
    )
  ) noreturn

  unreachable

ok:
  ret void
}

; default LinkedList is i8 data
define %LL* @AllocNode() {

  %alloc = call noalias i8*
    @malloc(i64 16) ; i64 and i64

  %ptr = bitcast i8* %alloc to %LL*

  ret %LL* %ptr
}

; pun intended
define void @FreeNode(%LL* %Node) {

  %1 = bitcast %LL* %Node to i8*

  call void
    @FreeI8(i8* %1)

  ret void
}

; improve alloc logic
define i8* @AllocI8(i64 %size) {

  ; i8*
  %ptr = call noalias i8*
    @malloc(i64 %size)

  ; may kill the program
  call void
    @IsValidPtr(
      i8* %ptr
  )

  ret i8* %ptr
}

define void @FreeI8(i8* %ptr) {

  call void
    @free(i8* %ptr)

  ret void
}

declare noalias i8* @malloc(i64)
declare void        @free(i8*)
declare void        @Die(i8*) noreturn
