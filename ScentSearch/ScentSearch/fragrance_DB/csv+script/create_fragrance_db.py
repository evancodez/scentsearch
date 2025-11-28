import csv
import json
import re

def extract_fragrance_id(url):
    """Extract the fragrance ID from the Fragrantica URL."""
    # URL format: https://www.fragrantica.com/perfume/brand/name-ID.html
    match = re.search(r'-(\d+)\.html$', url)
    if match:
        return match.group(1)
    return None

def generate_image_url(fragrance_id):
    """Generate the image URL from the fragrance ID."""
    if fragrance_id:
        return f"https://fimgs.net/mdimg/perfume-thumbs/375x500.{fragrance_id}.jpg"
    return None

def parse_notes(notes_string):
    """Parse notes string into a list."""
    if not notes_string or notes_string.strip() == '':
        return []
    return [note.strip() for note in notes_string.split(',')]

def main():
    fragrances = []
    
    with open('fra_cleaned.csv', 'r', encoding='latin-1') as csvfile:
        reader = csv.DictReader(csvfile, delimiter=';')
        
        for row in reader:
            url = row.get('url', '')
            fragrance_id = extract_fragrance_id(url)
            
            fragrance = {
                'brand': row.get('Brand', ''),
                'name': row.get('Perfume', '').replace('-', ' ').title(),
                'notes': {
                    'top': parse_notes(row.get('Top', '')),
                    'middle': parse_notes(row.get('Middle', '')),
                    'base': parse_notes(row.get('Base', ''))
                },
                'year': row.get('Year', ''),
                'image_url': generate_image_url(fragrance_id)
            }
            
            fragrances.append(fragrance)
    
    # Write to JSON file
    with open('fragrance_database.json', 'w', encoding='utf-8') as jsonfile:
        json.dump(fragrances, jsonfile, indent=2, ensure_ascii=False)
    
    print(f"Successfully converted {len(fragrances)} fragrances to JSON!")
    print("Output saved to fragrance_database.json")

if __name__ == '__main__':
    main()
