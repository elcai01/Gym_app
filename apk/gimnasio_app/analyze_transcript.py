import json

def analyze_transcript():
    transcript_path = r"C:\Users\edwin\.gemini\antigravity\brain\4d790c8e-60cb-41f6-8855-d607c1370de1\.system_generated\logs\transcript.jsonl"
    with open(transcript_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    for line in lines:
        try:
            data = json.loads(line)
            if 'tool_calls' in data:
                for call in data['tool_calls']:
                    name = call.get('name')
                    if name in ['replace_file_content', 'multi_replace_file_content']:
                        args = call.get('args', {})
                        if 'TargetFile' in args and 'main.dart' in args['TargetFile']:
                            print(f"--- STEP {data.get('step_index')} ---")
                            print(f"Tool: {name}")
                            if 'Instruction' in args:
                                print(f"Instruction: {args['Instruction']}")
                            if 'ReplacementContent' in args:
                                print(f"Content: {args['ReplacementContent'][:200]}...")
                            if 'ReplacementChunks' in args:
                                print(f"Chunks: {len(args['ReplacementChunks'])}")
        except Exception as e:
            pass

if __name__ == "__main__":
    analyze_transcript()
