
test:
	@echo "ceci est un test"

bone: bone.s
	vasm -m68080 -devpac -Fhunkexe -o Bone Bone.s

