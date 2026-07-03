import os
import re

def refactor_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add ApiClient import if not present
    if 'import \'package:http/http.dart\' as http;' in content:
        if 'api_client.dart' not in content:
            # We need to compute relative path to api_client.dart, but for simplicity we can just replace http.
            pass

    # Actually, let's just do a simple string replace for now.
    # We will replace `http.get` with `ApiClient.get` etc.
    new_content = content.replace('http.get(', 'ApiClient.get(')
    new_content = new_content.replace('http.post(', 'ApiClient.post(')
    new_content = new_content.replace('http.put(', 'ApiClient.put(')
    new_content = new_content.replace('http.delete(', 'ApiClient.delete(')
    
    # We need to import ApiClient. If it's main.dart, it's just `import 'utils/api_client.dart';`
    if 'ApiClient.' in new_content and 'api_client.dart' not in new_content:
        # Just put it after the http import
        import_statement = "import 'package:http/http.dart' as http;"
        new_import = "import 'package:http/http.dart' as http;\nimport 'package:gimnasio_app/utils/api_client.dart';"
        
        if import_statement in new_content:
            new_content = new_content.replace(import_statement, new_import)
        else:
            # Maybe it uses double quotes
            new_content = new_content.replace('import "package:http/http.dart" as http;', 'import "package:http/http.dart" as http;\nimport "package:gimnasio_app/utils/api_client.dart";')

    if content != new_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Refactored {filepath}")

def main():
    root_dir = r"d:\Proyectos\Gimnasio_app\apk\gimnasio_app\lib"
    for subdir, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                refactor_file(os.path.join(subdir, file))

if __name__ == "__main__":
    main()
