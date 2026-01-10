import json
import matplotlib.pyplot as plt

# Path to your AcCoRD summary file
file_path = "/Users/nihara/Downloads/AcCoRD-1.4.2/bin/results/accord_sample_communication_chemical_hardware_SEED1_summary.txt"


# Step 1: Read the file as plain text
with open(file_path, "r") as f:
    content = f.read()

# Step 2: Split into separate JSON objects
json_blocks = content.strip().split("}\n{")

# Step 3: Fix each block to be a valid JSON string
json_blocks = [
    ("{" + block + "}") if not block.startswith("{") else block
    for block in json_blocks
]
json_blocks = [
    block if block.endswith("}") else (block + "}") for block in json_blocks
]

# Step 4: Parse each block as a dictionary
parsed_data = [json.loads(block) for block in json_blocks]

# --- OPTIONAL: Display all keys in each block ---
print("🧾 Parsed JSON Blocks:")
for i, data in enumerate(parsed_data):
    print(f"\n--- JSON Block {i+1} ---")
    for key in data:
        print(f"{key}: {type(data[key])}")

# Step 5: Plot a graph from RecordInfo (Passive Observers)
record_info = parsed_data[1]["RecordInfo"]

# Extract values for plotting
observer_ids = [rec["ID"] for rec in record_info]
max_count_lengths = [rec["MaxCountLength"] for rec in record_info]

# Step 6: Plot
plt.figure(figsize=(10, 6))
plt.bar(observer_ids, max_count_lengths, color='skyblue')
plt.xlabel("Observer ID")
plt.ylabel("Max Count Length")
plt.title("Max Count Length per Passive Observer")
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.tight_layout()
plt.show()
