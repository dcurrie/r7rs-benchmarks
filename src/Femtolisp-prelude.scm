(define-macro (import . rest)
  #t)
(define (flush-output-port stream)
  #f)
(define (jiffies-per-second)
  1)
(define (current-jiffy)
  (time.now))
(define (current-second)
  (time.now))
(define (this-scheme-implementation-name)
  (string-append "femtolisp-" "unknown"))

(define (round x) (truncate (if (< x 0) (- x 0.5) (+ x 0.5))))

;;;; taken from aliases.scm
; definitions of standard scheme procedures in terms of femtolisp procedures
; sufficient to run the R5RS version of psyntax

;(define top-level-bound? bound?)
(define (eval-core x) (eval x))
(define (symbol-value s) (top-level-value s))
(define (set-symbol-value! s v) (set-top-level-value! s v))
(define (eval x)
  ((compile-thunk (expand
                   (if (and (pair? x)
                            (equal? (car x) "noexpand"))
                       (cadr x)
                       x)))))
(define (command-line) *argv*)

;(define gensym
;  (let (($gensym gensym))
;    (lambda ((x #f)) ($gensym))))

(define-macro (begin0 first . rest)
  `(prog1 ,first ,@rest))

(define vector-ref aref)
(define vector-set! aset!)
(define vector-length length)
(define make-vector vector.alloc)
(define (vector-fill! v f)
  (for 0 (- (length v) 1)
       (lambda (i) (aset! v i f)))
  #t)
;(define (vector-map f v) (vector.map f v))
(define (vector-map f v)
  (let* ((n (length v))
         (nv (vector.alloc n)))
    (for 0 (- n 1)
         (lambda (i)
           (aset! nv i (f (aref v i)))))
    nv))

(define array-ref aref)
(define (array-set! a obj i0 . idxs)
  (if (null? idxs)
      (aset! a i0 obj)
      (error "array-set!: multiple dimensions not yet implemented")))

(define (array-dimensions a)
  (list (length a)))

(define (complex? x) #f)
(define (real? x) (number? x))
(define (rational? x) (integer? x))
(define (exact? x) (integer? x))
(define (inexact? x) (not (exact? x)))
(define (flonum? x) (not (exact? x)))
(define quotient div0)
(define remainder mod0)
(define (inexact x) x)
(define (exact x)
  (if (or (exact? x) (= x (truncate x)))
      (truncate x)
      (error "exact real numbers not supported")))
(define (exact->inexact x) (double x))
(define (inexact->exact x)
  (if (or (integer-valued? x) (= x (truncate x)))
      (truncate x)
      (error "exact real numbers not supported")))
(define (floor x)   (if (< x 0) (truncate (- x 0.5)) (truncate x)))
(define (ceiling x) (if (< x 0) (truncate x) (truncate (+ x 0.5))))
(define (finite? x) (and (< x +inf.0) (> x -inf.0)))
(define (infinite? x) (or (equal? x +inf.0) (equal? x -inf.0)))

(define (char->integer c) (fixnum c))
(define (integer->char i) (wchar i))
;(define char-upcase char.upcase)
;(define char-downcase char.downcase)
(define char=? eqv?)
(define char<? <)
(define char>? >)
(define char<=? <=)
(define char>=? >=)
(define (char-whitespace? c) (not (not (string.find *whitespace* c))))
(define (char-numeric? c) (not (not (string.find "0123456789" c))))

(define string=? eqv?)
(define string<? <)
(define string>? >)
(define string<=? <=)
(define string>=? >=)
(define string-copy copy)
(define string-append string)
(define string-length string.count)
(define string->symbol symbol)
(define (symbol->string s) (string s))
(define symbol=? eq?)
(define (make-string k (fill #\space))
  (string.rep fill k))

(define (string-ref s i)
  (string.char s (string.inc s 0 i)))

(define (list->string l) (apply string l))

(define-macro (do vars test-spec . commands)
  (let ((loop (gensym))
        (test-expr (car test-spec))
        (vars  (map car  vars))
        (inits (map cadr vars))
        (steps (map (lambda (x)
                      (if (pair? (cddr x))
                          (caddr x)
                          (car x)))
                    vars)))
    `(letrec ((,loop (lambda ,vars
                       (if ,test-expr
                           (begin
                             ,@(cdr test-spec))
                           (begin
                             ,@commands
                             (,loop ,.steps))))))
       (,loop ,.inits))))

(define (string->list s)
  (do ((i (sizeof s) i)
       (l '() (cons (string.char s i) l)))
      ((= i 0) l)
    (set! i (string.dec s i))))

(define (substring s start end)
  (string.sub s (string.inc s 0 start) (string.inc s 0 end)))

(define (input-port? x) (iostream? x))
(define (output-port? x) (iostream? x))
(define (port? x) (iostream? x))
(define close-input-port io.close)
(define close-output-port io.close)
(define (read-char (s *input-stream*)) (io.getc s))
(define (peek-char (s *input-stream*)) (io.peekc s))
(define (write-char c (s *output-stream*)) (io.putc s c))
; TODO: unread-char
(define (port-eof? p) (io.eof? p))
(define (open-input-string str)
  (let ((b (buffer)))
    (io.write b str)
    (io.seek b 0)
    b))
(define (open-output-string) (buffer))
(define (open-string-output-port)
  (let ((b (buffer)))
    (values b (lambda () (io.tostring! b)))))

(define (get-output-string b)
  (let ((p (io.pos b)))
    (io.seek b 0)
    (let ((s (io.readall b)))
      (io.seek b p)
      (if (eof-object? s) "" s))))

(define (open-input-file name) (file name :read))
(define (open-output-file name) (file name :write :create))

(define (current-input-port (p *input-stream*))
  (set! *input-stream* p))
(define (current-output-port (p *output-stream*))
  (set! *output-stream* p))

;(define (input-port-line p)
;  ; TODO
;  1)

(define get-datum read)
(define (put-datum port x)
  (with-bindings ((*print-readably* #t))
                 (write x port)))

(define (put-u8 port o) (io.write port (uint8 o)))
(define (put-string port s (start 0) (count #f))
  (let* ((start (string.inc s 0 start))
         (end (if count
                  (string.inc s start count)
                  (sizeof s))))
    (io.write port s start (- end start))))

(define (io.skipws s)
  (let ((c (io.peekc s)))
    (if (and (not (eof-object? c)) (char-whitespace? c))
        (begin (io.getc s)
               (io.skipws s)))))

(define (with-output-to-file name thunk)
  (let ((f (file name :write :create :truncate)))
    (unwind-protect
     (with-output-to f (thunk))
     (io.close f))))

(define (with-input-from-file name thunk)
  (let ((f (file name :read)))
    (unwind-protect
     (with-input-from f (thunk))
     (io.close f))))

(define (call-with-input-file name proc)
  (let ((f (open-input-file name)))
    (prog1 (proc f)
           (io.close f))))

(define (call-with-output-file name proc)
  (let ((f (open-output-file name)))
    (prog1 (proc f)
           (io.close f))))

(define (file-exists? f) (path.exists? f))
(define (delete-file name) (void)) ; TODO

(define (display x (port *output-stream*))
  (with-output-to port (princ x))
  #t)

(define assertion-violation 
  (lambda args 
    (display 'assertion-violation)
    (newline)
    (display args)
    (newline)
    (car #f)))

(define pretty-print write)

(define (memp proc ls)
  (cond ((null? ls) #f)
        ((pair? ls) (if (proc (car ls))
                        ls
                        (memp proc (cdr ls))))
        (else (assertion-violation 'memp "Invalid argument" ls))))

(define (assp pred lst)
  (cond ((atom? lst) #f)
        ((pred       (caar lst)) (car lst))
        (else        (assp pred  (cdr lst)))))

(define (for-all proc l . ls)
  (or (null? l)
      (and (apply proc (car l) (map car ls))
           (apply for-all proc (cdr l) (map cdr ls)))))
(define andmap for-all)

(define (exists proc l . ls)
  (and (not (null? l))
       (or (apply proc (car l) (map car ls))
           (apply exists proc (cdr l) (map cdr ls)))))
(define ormap exists)

(define cons* list*)

(define (fold-left f zero lst)
  (if (null? lst) zero
      (fold-left f (f zero (car lst)) (cdr lst))))

(define (foldr f zero lst)
  (if (null? lst) zero
      (f (car lst) (foldr f zero (cdr lst)))))
(define fold-right foldr)

(define (partition pred lst)
  (let ((s (separate pred lst)))
    (values (car s) (cdr s))))

(define (dynamic-wind before thunk after)
  (before)
  (unwind-protect (thunk)
                  (after)))

(let ((*properties* (table)))
  (set! putprop
        (lambda (sym key val)
          (let ((sp (get *properties* sym #f)))
            (if (not sp)
                (let ((t (table)))
                  (put! *properties* sym t)
                  (set! sp t)))
            (put! sp key val))))

  (set! getprop
        (lambda (sym key)
          (let ((sp (get *properties* sym #f)))
            (and sp (get sp key #f)))))

  (set! remprop
        (lambda (sym key)
          (let ((sp (get *properties* sym #f)))
            (and sp (has? sp key) (del! sp key))))))

; --- gambit

(define arithmetic-shift ash)
(define bitwise-and logand)
(define bitwise-or logior)
(define bitwise-not lognot)
(define bitwise-xor logxor)

(define (include f) (load f))
(define (with-exception-catcher hand thk)
  (trycatch (thk)
            (lambda (e) (hand e))))

(define (current-exception-handler)
  ; close enough
  (lambda (e) (raise e)))

(define make-table table)
(define table-ref get)
(define table-set! put!)
(define (read-line (s *input-stream*))
;  (io.flush *output-stream*)
;  (io.discardbuffer s)
  (io.readline s))
(define (shell-command s) 1)
(define (error-exception-message e) (cadr e))
(define (error-exception-parameters e) (cddr e))

(define (with-output-to-string nada thunk)
  (let ((b (buffer)))
    (with-output-to b (thunk))
    (io.tostring! b)))

(define (read-u8) (io.read *input-stream* 'uint8))
(define modulo mod)

;; -- missing expt, gcd, lcm, exact-integer?, write-string

(define (square x) (* x x))
(define (expt b p)
  (cond ((= p 0) 1)
        ((= b 0) 0)
        ((even? p) (square (expt b (div0 p 2))))
        (#t (* b (expt b (- p 1))))))

(define (gcd a b)
  (cond ((= a 0) b)
        ((= b 0) a)
        ((< a b)  (gcd a (- b a)))
        (#t       (gcd b (- a b)))))

(define exact-integer? integer?)

(define (write-string s . opts)
  (let ((port (if (null? opts) *standard-output* (car opts))))
    (apply io.write port s (cdr opts))))

(define (lcm x y)
  (quotient (abs (* x y)) (gcd x y)))

;; --  call/cc hack to make some tests run
;;
(define (call-with-current-continuation fun)
  (let ((tag (list 'tag))
        (res #f))
    (trycatch (set! res (fun (lambda (r) (set! res r) (raise tag))))
      (lambda (e) (if (eq? e tag) #t (raise e))))
    res))

;; -- it pains me to write sqrt here, it really should be a builtin
;;
(define (sqrt x)
  (if (<= x 0)
    x
    (let loop ((i 13) (guess 2.0))
     (if (<= i 0)
       guess
       (loop (- i 1) (/ (+ guess (/ x guess)) 2))))))

;; -- it pains me to write sin here, it really should be a builtin
;; -- see https://stackoverflow.com/questions/18646634/scheme-new-sin-x-function
;;
(define (sin x)
  (let* ((last-value 1)
        (n-odd-fact ;; calculates the next odd factorial
          (lambda (j)
            (begin (set! last-value (* j (- j 1) last-value))
                    last-value)))) ;;memioze(ish) last call
    (let loop ((i 0) (sum x))
      (let ((term (if (= i 0)
                    0.0
                    (* (if (odd? i) -1 1)
                       (/ (expt x (+ 1 (* 2 i)))
                          (n-odd-fact (+ 1 (* 2 i))))))))
         (if (= i 20) ;; bigger than 20 is hard for factorial, good enough for accuracy
             (double sum)
             (loop (+ i 1) (+ sum term)))))))
