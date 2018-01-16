---
title: Introducción a la verificación formal
author: David Charte
institute: Universidad de Granada
toc: true
numbersections: true
lang: es-ES
references:
    - id: sel4
      author:
        family: Doe
        given: [John, F.]
      title: Article
      page: 33-34
      issued:
        year: 2006
      type: article-journal
      volume: 6
      container-title: Journal of Generic Studies
---

\clearpage

# Motivación

Las implementaciones software y los diseños hardware están sujetos a la introducción de errores o *bugs* que pueden impedir el correcto funcionamiento bajo determinadas circunstancias. Realizar una comprobación exhaustiva que descarte toda posibilidad de bug puede ser una tarea extremadamente difícil y costosa. Sin embargo, es un requerimiento conveniente para diversas aplicaciones, como protocolos criptográficos, software crítico, o circuitería de sistemas empotrados. 

La verificación formal es una técnica que permite demostrar la corrección de una implementación software o hardware respecto de una especificación formal mediante métodos formales matemáticos. Puesto que se trata de una herramienta matemática, permite asegurar el funcionamiento correcto de los programas o dispositivos bajo determinadas condiciones asumidas, por lo que conviene reducir en la medida de lo posible estas hipótesis, y que se verifiquen en general.

En este trabajo se describe el marco teórico necesario para comprender las bases de los distintos enfoques por los que se efectúa verificación formal. Este incluye conceptos sobre lógica, tipos, sistemas de cálculo y un resultado muy relevante, la correspondencia de Curry-Howard. Posteriormente, se tratan los enfoques desde los que se trata la verificación formal, mencionando el software que la hace posible. A continuación, se describen aplicaciones en distintos ámbitos de la informática.

# Marco teórico

Para comprender los motivos por los que es posible asegurar la corrección de programas y hardware, y el funcionamiento del proceso, es necesario conocer los fundamentos teóricos por los cuales se relacionan la teoría de tipos y la lógica intuicionista.

## Lógicas

En esta sección se aportan conceptos intuitivos acerca de las lógicas utilizadas en verificación formal.

### Lógica intuicionista

La lógica intuicionista o constructivista se refiere a los sistemas lógicos en los cuales toda nueva afirmación debe ser probada de forma constructiva para ser aceptada como verdadera. En concreto, esta lógica no incluye la ley del tercio excluso ($p\vee\neg p$) ni la eliminación de la doble negación ($\neg \neg p \rightarrow p$), por lo que no se pueden demostrar proposiciones mediante reducción al absurdo.

### Lógica de orden superior

La lógica de orden superior abarca todas las lógicas de n-ésimo orden. La lógica de primer orden permite cuantificar  (con $\exists$, existe, y $\forall$, para todo) variables que se refieren a elementos del discurso. Por ejemplo,
\begin{center}
``existe $x$ tal que $x$ es mamífero y $x$ tiene pico'': $\exists x(x\in M \wedge x\in P)$
\end{center}
es una proposición válida. La de segundo orden cuantifica también relaciones sobre estas variables, p.ej.
\begin{center}
``existe una clase $O$ de animales tal que para cada animal $x$, si $x$ es mamífero y tiene pico entonces es de clase $O$'':  $\exists O \forall x (x\in M\wedge x\in P\rightarrow x\in O)$.
\end{center}
La lógica de tercer orden permite cuantificar relaciones entre relaciones, y así sucesivamente.

## Teoría de tipos

La teoría de tipos estudia los sistemas formales que utilizan tipos para restringir las operaciones que se pueden aplicar a cada término. En particular, las funciones se modelan en teoría de tipos como objetos de tipo `a -> b`, llevando elementos de tipo `a` en tipo `b`.

### Tipado dependiente

Un *tipo dependiente* es un tipo cuya definición depende de un valor.

Ejemplo: `matrix(n,m)` para multiplicación de matrices: `(Matrix(k,m), Matrix(m,n)) -> Matrix(k,n)`.

## Sistemas de cálculo. Turing-completitud

Del estudio del "Entscheidungsproblem" surgieron varias propuestas de sistemas de cálculo (o cómputo), las cuales son capaces de resolver exactamente el mismo conjunto de problemas, denominados *efectivamente calculables*. Estos sistemas son:

- las *funciones recursivas* propuestas por Gödel,
- el *cálculo lambda* de Church,
- y las *máquinas universales* de Turing.

Los lenguajes de programación desarrollados para ordenadores son, en general, Turing-completos, lo que quiere decir que calculan el mismo conjunto de problemas que estos tres sistemas. Desde el punto de vista teórico, por tanto, son equivalentes y se puede sustituir un lenguaje por cualquiera de estos sistemas cuando sea conveniente. La ventaja es que el cálculo lambda o las máquinas de Turing tienen un comportamiento más sencillo de describir y esto facilita la argumentación lógica sobre ellos.

Es interesante notar que el cálculo lambda se asemeja a un lenguaje de programación muy sencillo sin tipos, pero puede ser extendido para incluirlos. De hecho, uno de los sistemas de cálculo usados para desarrollar asistentes de demostraciones es el cálculo lambda simplemente tipado. El único constructor de tipos que incluye es la función, por lo que los tipos que se obtienen son funciones sobre (funciones sobre (...)) los tipos básicos de los que se parta. Una consecuencia importante es que el cálculo lambda simplemente tipado no es Turing-completo.

## Correspondencia de Curry-Howard

En 1934, Haskell Curry observó que cada tipo asignado a una función se podía relacionar con una proposición involucrando una implicación (del tipo "si ... entonces ... "), y siguiendo esta relación, al leer el tipo de cualquier función dada se llegaba a una proposición demostrable. 

La correspondencia de Curry-Howard establece una identificación entre tipos y proposiciones lógicas. En esta correspondencia, una proposición verdadera se identifica con un tipo del cual existe al menos un objeto, y una proposición falsa corresponde a un tipo para el cual es imposible construir un objeto.

A continuación se describen las identificaciones entre construcciones de tipos y lógicas que conforman la correspondencia:

<!--### La correspondencia-->

*Tipo pareja. * Del tipo pareja `(a,b)` sólo podemos construir elementos si existen elementos tanto para `a` como para `b`. Por tanto, se corresponde con la conjunción lógica: $a\wedge b$ sólo se demuestra con una demostración para $a$ y otra para $b$.

*Tipo alternativa. * El tipo alternativa `(a|b)` (similar a los `union`s de C o `Either` en Haskell) describe elementos que son de uno de los dos tipos, `a` o `b`. Así, tiene elementos si al menos hay elementos para alguno de los dos tipos, correspondiéndose con la disyunción lógica: $a\vee b$ es cierto si lo es al menos $a$ o $b$.

*Tipo función. * El tipo función lo denotaremos `a -> b` e indica la entrada de objetos del tipo antecedente y la salida de objetos del tipo consecuente. Se identifica con la implicación: existen funciones que toman `a` y devuelven `b` si y solo si $a\rightarrow b$ es verdad. Algunos ejemplos de funciones son:

- Tautología: $a\rightarrow a$ es siempre verdad, así que siempre existe una función que tome un objeto de tipo `a` y devuelva uno del mismo tipo. En efecto, la función identidad `id x = x` es de tipo `a -> a`.
- Proyección: Si partimos del tipo pareja, podemos construir la función que devuelve el primer elemento: `left (x, y) = x` de tipo `(a,b) -> a`. Esto nos demuestra que la proposición lógica $a\wedge b\rightarrow a$ es verdadera.

# Verificación formal de software

## Enfoques

### Verificación de modelos

La verificación de modelos consiste en la exploración exhaustiva de todos los estados y transiciones del modelo matemático asociado al sistema. Esto es aplicable principalmente a sistemas con un número finito de estados, pero también a algunos infinitos que se puedan representar finitamente de forma abstracta. En cualquier caso, no es una técnica adaptable a grandes sistemas.

Las propiedades verificadas mediante esta técnica suelen venir descritas en una lógica temporal, que permite realizar afirmaciones que involucran el tiempo, p.ej. "cada vez que ocurre $x$ el sistema responde $y$".

### Verificación deductiva

La verificación deductiva consiste en construir una especificación formal del comportamiento de un sistema y realizar una serie de demostraciones para deducir que la implementación la cumple. Generalmente las demostraciones se resuelven con asistentes de demostración, aunque otras opciones son solucionadores de teorías de satisfacibilidad módulo y demostradores automáticos.

## Asistentes de demostración

Un asistente de demostración o demostrador interactivo es un programa que ayuda al desarrollo de demostraciones formales mediante colaboración entre el humano y la máquina. Generalmente se compone de un editor donde el humano escribe una guía para la demostración, siendo esta completada y verificada por la máquina.

Los asistentes incluyen una teoría de tipos que determina las características de la lógica con la quese relaciona. Utilizan tácticas y estrategias para encontrar un elemento del tipo buscado (por Curry-Howard, encontrar este elemento equivale a disponer de una demostración).

### Algunos asistentes

- Agda: implementado sobre Haskell, usa lógica de orden superior y tipos dependientes.
- Coq: implementado sobre OCaml, también usa lógica de orden superior y tipos dependientes
- Isabelle: implementado sobre ML estándar, utiliza lógica de orden superior pero sólo dispone de tipado simple.
- F*, HOL, PVS...

### Ejemplo: una demostración sobre Coq

~~~coq
(** Recursive polymorphic definition of trees *)
Inductive tree (X:Type) : Type :=
  | nilt : tree X
| node : X -> tree X -> tree X -> tree X.

(** Auxiliary lemmas about refl *)
Lemma refl_involutive : forall {X:Type} (t:tree X),
  refl (refl t) = t.
Proof.
  intros X t.
  induction t as [|a izq Hiz der Hdr].
    reflexivity.
    simpl. rewrite -> Hiz. rewrite -> Hdr. reflexivity.
Qed.
~~~

Fuente: <https://github.com/M42/recorridosArboles>.


# Aplicaciones

## Sistemas operativos

Aplicada a sistemas operativos, la verificación formal requiere tal esfuerzo de desarrollo y computación que únicamente es viable con kernels muy sencillos. Por ejemplo la verificación de seL4 consiste en unas 200000 líneas de demostración para 7500 líneas de código C. Por otro lado, el coste promedio estimado de la línea de código de seL4 es de 400$ frente a los 10000$ por línea de los programas de alta fiabilidad que cumplen la certificación *Common Criteria EAL6*.

Los primeros intentos de construir sistemas operativos verificados formalmente surgieron en los años 70 y 80 (UCLA Secure Unix, Provably Secure Operating System), descubriéndose que las simplificaciones requeridas para hacer viable la verificación hacían el sistema un orden de magnitud más lento. Los esfuerzos más recientes, como PikeOS y seL4, consiguen sortear este obstáculo.

PikeOS es un micro-kernel orientado a aplicaciones críticas y en tiempo real que cumple diversos estándares de seguridad. Consiste en menos de 10000 líneas de código y soporta la ejecución paralela de varias aplicaciones acordes a distintas certificaciones de seguridad al igual que ejecución de sistemas operativos sobre PikeOS en modo hipervisor.

seL4 es un micro-kernel de la familia L4 cuya primera demostración de corrección se completó en 2009, convirtiéndolo en el primer SO de propósito general verificado. En 2014 se liberó su código bajo licencia GPLv2. La verificación está realizada sobre el asistente de demostraciones Isabelle con lógica de orden superior. Se compone de varias capas: primero una especificación abstracta que describe lo que hace el kernel sin detallar cómo, después una especificación ejecutable y por último una implementación en C asociada a la prueba sobre Isabelle.

Otros ejemplos de proyectos de sistemas verificados son VFiasco y Verisoft. Otros sistemas asociados a alta seguridad sólo ofrecen determinadas propiedades como seguridad de tipado (Singularity) o separación de datos (Integrity).

## Software

La verificación se suele utilizar para construir compiladores certificados, como CompCert C (sobre Coq)[^fn1]. También existe el Project Everest, una iniciativa cuyo objetivo es construir un stack HTTPS completamente verificado. En particular, es interesante la librería de criptografía HACL*, escrita en F* y ya utilizada en Firefox\footnote{Desde la versión 57[^fn2].

[^fn1]: Otros proyectos de procesadores de lenguajes verificados: <https://github.com/coq/coq/wiki/List%20of%20Coq%20PL%20Projects>
[^fn2]: <https://blog.mozilla.org/security/2017/09/13/verified-cryptography-firefox-57/>

## Hardware

En hardware se puede utilizar verificación de modelos hasta cierto punto, siempre que se trabaja con circuitos digitales con un número finito manejable de estados. También existe el lenguaje de descripción de hardware Fe-Si escrito sobre Coq, que permite especificar un hardware y convertirlo a lenguaje VHDL de forma que el comportamiento sea exactamente el descrito.

Mediante verificación formal se ha llegado a demostrar la propiedad de vivacidad (espera acotada, ausencia de interbloqueos, y de inanición) en el bus *Runway* de HP. También se ha construido un procesador DLX completamente verificado, VAMP (*Verified Architecture Microprocessor*).

# Conclusiones

La verificación formal abarca un conjunto de técnicas con una fuerte base teórica matemática, y presenta generalmente un coste computacional alto. Sin embargo, puede ofrecer mayor seguridad a menor coste económico que otras alternativas. El enfoque más frecuentemente encontrado en aplicaciones reales es la verificación deductiva con asistentes de demostración.