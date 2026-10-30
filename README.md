# Olympius

## Como adicionar PDFs
1. Coloque o PDF na pasta da olimpíada: `materiais/oba`, `materiais/obmep`, `materiais/obr` ou `materiais/onee`.
   Use nomes em minúsculas, sem espaços e sem acentos (ex.: `oba-2025-nivel1.pdf`).
2. No `index.html`, procure `materialsData` e adicione uma linha em `items`:
   `{ name: "Nome que aparece no site", type: "PDF", link: "materiais/oba/arquivo.pdf" },`
3. Faça commit e push. O GitHub Pages atualiza em alguns minutos.

O campo `size` é opcional (ex.: `size: "2 MB"`).
