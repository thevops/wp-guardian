# wp-guardian
Bash script for keep secure WordPress website

Skrypt dodany do systemowego crona monitoruje WordPressa
- wtyczki
- motywy
- core WordPressa
- użytkowników
- intergralność plików
- potencjalnie niebezpieczne pliki

Używa wp-cli: https://wp-cli.org/

### Konfiguracja
- Stworz katalog .wp-guardian/ w katalogu strony
- Sklonuj do niego to repozytorium
- Wypełnij dane w pliku
	- adres email, na który wysyłane będą raporty
	- ścieżka do katalogu ze stroną
	- zakomentuj moduły, które nie będą monitorowane (na samym dole skryptu)
	- reszta opcjonalnie - dla zaawansowanych

