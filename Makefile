subzero: subzero.hs
	ghc -O2 --make -static -optc-static -optl-static subzero.hs -fvia-C -optl-pthread


docker:: subzero
	docker build -t subzero:latest .
