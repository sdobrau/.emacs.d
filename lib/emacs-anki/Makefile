.PHONY: test compile clean

test:
	python3 -m py_compile emacs_anki.py tests/test_emacs_anki.py
	python3 -m unittest discover -s tests -v
	emacs --batch -L . -l tests/check.el

compile:
	emacs --batch -L . --eval '(setq byte-compile-error-on-warn t)' \
		-f batch-byte-compile emacs-anki.el
	rm -f emacs-anki.elc

clean:
	rm -rf __pycache__ tests/__pycache__ emacs-anki.elc
