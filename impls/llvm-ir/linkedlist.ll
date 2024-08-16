
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

; the @LL.Iter is just a simple abstraction
; on top of the linked list, it simply points to
; one Node at a time, and has a straightforward
; @LL.Next/@LL.Peek API, suitable for a Tokenizer.

@LL.Iter = global %LL* null

define void @LL.Init() {
  
  ; initialize Tail and Iter as pointers to Head
  store %LL* @LL.Head, %LL** @LL.Iter
  store %LL* @LL.Head, %LL** @LL.Tail

  ret void
}

define i8* @LL.GetData(%LL* %l) {

  ; get data at offset 0 ( i8* )
  %1 = getelementptr %LL, %LL* %l, i32 0, i32 0

  ; load the data as i8*
  %data = load i8*, i8** %1

  ret i8* %data
}

define %LL* @LL.GetNext(%LL* %l) {

  ; get data at offset 1 ( LL* )
  %1 = getelementptr %LL, %LL* %l, i32 0, i32 1

  ; load the data as LL*
  %next = load %LL*, %LL** %1

  ret %LL* %next
}

define i8* @LL.Next() {

;     the workflow is pretty straightforward

;       Load @Iter     -ated node

;       Get  data      From @Iter-ated node
;       Get  next node From @Iter-ated node

;     If next node is null:
;       Set @Iter      To next node

;     If it is not:
;       Set @Iter      To @LL.Head ( resetting it )

;       Ret  data


  %it = load %LL*, %LL** @LL.Iter

  %data = call i8*
    @LL.GetData(%LL* %it)

  %next = call %LL*
    @LL.GetNext(%LL* %it)

  ; if Next element is NULL, do not advance,
  ; assign @LL.Head to @Iter instead.

  ; this assures that the next @LL.Next/@LL.Peek call will
  ; return NULL, signaling an end, but won't prevent the
  ; caller from doing more iterations.

  %isNull = icmp eq %LL* %next, null
  br i1 %isNull, label %reset, label %advance

reset:
  store %LL* @LL.Head, %LL** @LL.Iter
  br label %done

advance:

  ; advance Iterator by pointing to the next element

  store %LL* %next, %LL** @LL.Iter
  br label %done

done:
  ret i8* %data
}

define i8* @LL.Peek() {

;       Load @Iter  -ated node

;       Get  data   From @Iter-ated node
;       Ret  data

  %it = load %LL*, %LL** @LL.Iter

  %data = call i8*
    @LL.GetData(%LL* %it)

  ret i8* %data
}

define void @LL.Join(%LL* %l) {

;       %l is a pointer to a Node, this
;       function appends it to the end of
;       the list by setting current @Tail.Next
;       as %l and then making the whole @Tail
;       point to %l.

;    the workflow goes like:

;       Load @Tail node
;       Get  next  From @Tail
;       Set  next  From @Tail To %l (next now points to whatever %l points to)
;       Set  @Tail            To %l (@Tail now points to whatever %l points to)

  %tail = load %LL*, %LL** @LL.Tail

  ; Not using GetNext because i don't need the extra
  ; Load-ing step, i need to modify the struct itself.

  %tail_next = getelementptr %LL, %LL* %tail, i32 0, i32 1

  ; Set next From @Tail To %l
  store %LL* %l, %LL** %tail_next

  ; Set @Tail To %l
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

define void @LL.Clean() {

  ; TODO: document this

  %curr = alloca %LL*

  ; head is automatically managed memory
  %second = call %LL*
    @LL.GetNext(%LL* @LL.Head)

  store %LL* %second, %LL** %curr

  ; is the second element (the one we start in) null?
  %shouldNotIter = icmp eq %LL* %second, null

  ; if so, don't try to free it and segfault
  br i1 %shouldNotIter, label %done, label %iter

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

