#!/bin/bash

# Sugestões de países principais
SUGGESTED_COUNTRIES=(
  "Brazil"
  "United States"
  "China"
  "India"
  "Canada"
  "Germany"
)

# Função para mostrar sugestões
show_suggestions() {
  echo "========================================="
  echo "Países sugeridos:"
  echo "========================================="
  for country in "${SUGGESTED_COUNTRIES[@]}"; do
    echo "  - $country"
  done
  echo "========================================="
  echo ""
  echo "Uso: $0 \"<nome_do_país>\""
  echo "Exemplo: $0 \"Brazil\""
  echo "         $0 \"United States\""
  echo "         $0 \"Germany\""
  echo ""
  echo "Nota: Você pode passar qualquer país."
}

# Verificar se foi passado um parâmetro
if [ $# -eq 0 ]; then
  show_suggestions
  exit 0
fi

# Obter nome do país (aceita qualquer valor)
COUNTRY_NAME="$1"

# URL encode do nome do país (substituir espaços por %20)
COUNTRY_URL=$(echo "$COUNTRY_NAME" | sed 's/ /%20/g')

# Construir URL base
BASE_URL="https://www.credly.com/api/v1/directory?organization_id=63074953-290b-4dce-86ce-ea04b4187219&sort=alphabetical&filter%5Blocation_name%5D=${COUNTRY_URL}&page="

# Create datasource directory if it doesn't exist
mkdir -p datasource

# Nome do arquivo (substituir espaços por hífen e converter para minúsculas)
FILE_SUFFIX=$(echo "$COUNTRY_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
OUTPUT_FILE="datasource/github-certs-${FILE_SUFFIX}.csv"

# Escrever cabeçalho no arquivo CSV
echo "first_name,middle_name,last_name,badge_count" > "$OUTPUT_FILE"

# Iniciar a contagem de páginas
PAGE=1

echo "========================================="
echo "Buscando usuários de: $COUNTRY_NAME"
echo "Arquivo de saída: $OUTPUT_FILE"
echo "========================================="
echo ""

while true; do
  # Construir a URL completa
  URL="${BASE_URL}${PAGE}&format=json"
  
  # Fazer a solicitação HTTP e salvar o resultado
  RESPONSE=$(curl -s "$URL")
  
  # Verificar se a resposta contém dados
  DATA=$(echo "$RESPONSE" | jq -r '.data | length')
  
  if [ "$DATA" -eq 0 ]; then
    # Se não houver dados, interrompe o loop
    echo "Nenhum dado encontrado na página ${PAGE}. Interrompendo a execução."
    break
  fi
  
  # Extrair e adicionar os dados ao CSV
  echo "$RESPONSE" | jq -r '.data[] | [.first_name, .middle_name, .last_name, .badge_count] | @csv' >> "$OUTPUT_FILE"
  
  echo "Processou página ${PAGE}"
  
  # Incrementa a página
  PAGE=$((PAGE + 1))
done

echo ""
echo "========================================="
echo "Concluído!"
echo "País: $COUNTRY_NAME"
echo "Total de páginas processadas: $((PAGE - 1))"
echo "Dados salvos em: $OUTPUT_FILE"
echo "========================================="
