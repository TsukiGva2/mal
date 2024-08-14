
; Linked List type
%LL = type {
    i8*, ; data
    %LL* ; next
}

; this follows the design of all my files,
; of having single stateful objects mimicking
; classes.

; the fact that dot (.) is valid in identifiers
; allows us to do some really fun stuff.

@LL.Head = global %LL { i8* null, %LL* null }
@LL.Tail = global %LL* null

; Abstracting away details
@LL.Iter = global %LL* null

define void @LL.Init() {
  
  ; no need to null-initialize

  ;  %head_data = getelementptr %LL, %LL* @LL.Head, i32 0, i32 0
  ;  store i8* null, i8** %head_data

  ;  %head_next = getelementptr %LL, %LL* @LL.Head, i32 0, i32 1
  ;  store %LL* null, %LL** %1

  ; initialize Tail and Iter as pointers to Head
  store %LL* @LL.Head, %LL** @LL.Iter
  store %LL* @LL.Head, %LL** @LL.Tail

  ret void
}

define i8* @LL.GetData(%LL* %l) {

  ; get data at offset 0 ( i8* )
  %1 = getelementptr %LL, %LL* %l, i32 0, i32 0
  %data = load i8*, i8** %1

  ret i8* %data
}

define %LL* @LL.GetNext(%LL* %l) {

  ; get data at offset 1 ( LL* )
  %1 = getelementptr %LL, %LL* %l, i32 0, i32 1
  %next = load %LL*, %LL** %1

  ret %LL* %next
}

define i8* @LL.Next() {

  ; Get data from current Iter location
  ; and set @Iter to its next element

  %it = load %LL*, %LL** @LL.Iter

  %data = call i8*
    @LL.GetData(%LL* %it)

  %next = call %LL*
    @LL.GetNext(%LL* %it)

  %isNull = icmp eq %LL* %next, null
  br i1 %isNull, label %done, label %advance

advance:
  store %LL* %next, %LL** @LL.Iter
  br label %done

done:
  ret i8* %data
}

define i8* @LL.Peek() {

  %it = load %LL*, %LL** @LL.Iter

  %data = call i8*
    @LL.GetData(%LL* %it)

  ret i8* %data
}

define void @LL.Join(%LL* %l) {

  %tail = load %LL*, %LL** @LL.Tail

  ; (old tail) tail.next = %l (new tail)
  %tail_next = getelementptr %LL, %LL* %tail, i32 0, i32 1
  store %LL* %l, %LL** %tail_next

  ; storing pointer to %l as new Tail
  store %LL* %l, %LL** @LL.Tail

  ret void
}

define void @LL.Insert(i8* %newData) {

  %l = call %LL*
    @AllocNode()

  ; zeroing
  %data = getelementptr %LL, %LL* %l, i32 0, i32 0
  store i8* %newData, i8** %data

  %next = getelementptr %LL, %LL* %l, i32 0, i32 1
  store %LL* null, %LL** %next

  call void
    @LL.Join(%LL* %l)

  ret void
}

define void @LL.Clear() {

  %curr = alloca %LL*
  
  ; head is automatically managed memory
  %second = call %LL*
    @LL.GetNext(%LL* @LL.Head)

  store %LL* %second, %LL** %curr

  br label %iter

iter:
  ; loading current node ( stack allocated LL* )
  %node = load %LL*, %LL** %curr

  %next = call %LL*
    @LL.GetNext(%LL* %node)

  call void
    @FreeNode(%LL* %node)

  br label %check

check:
  ; storing Next node to current node so we free it
  store %LL* %next, %LL** %curr

  ; is it null tho?
  %isNull = icmp eq %LL* %next, null

  br i1 %isNull, label %done, label %iter

done:

  ; reset positions
  call void
    @LL.Init()

  ret void
}

declare %LL* @AllocNode()
declare void @FreeNode(%LL*)

