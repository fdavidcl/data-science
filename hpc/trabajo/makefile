default: presentacion.pdf

%.pdf: %.md
	pandoc -o $@ $< -t beamer --pdf-engine=xelatex
