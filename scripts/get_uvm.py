import os
import urllib.request
import tarfile
import shutil

# URL for UVM 1.2 (Standard Accellera release)
UVM_URL = "https://www.accellera.org/images/downloads/standards/uvm/uvm-1.2.tar.gz"
DEST_DIR = os.path.dirname(os.path.abspath(__file__))
UVM_DIR = os.path.join(DEST_DIR, "uvm-1.2")
TAR_FILE = os.path.join(DEST_DIR, "uvm-1.2.tar.gz")

def download_uvm():
    if os.path.exists(UVM_DIR):
        print(f"UVM 1.2 already exists at: {UVM_DIR}")
        return

    print(f"Downloading UVM 1.2 from {UVM_URL}...")
    try:
        # User-Agent header is sometimes needed to avoid 403
        headers = {'User-Agent': 'Mozilla/5.0'}
        req = urllib.request.Request(UVM_URL, headers=headers)
        with urllib.request.urlopen(req) as response, open(TAR_FILE, 'wb') as out_file:
            shutil.copyfileobj(response, out_file)
        print("Download complete.")
        
        print("Extracting...")
        with tarfile.open(TAR_FILE, "r:gz") as tar:
            tar.extractall(path=DEST_DIR)
        print(f"Extracted to: {UVM_DIR}")
        
        # Cleanup
        os.remove(TAR_FILE)
        print("Done.")
        
    except Exception as e:
        print(f"Error downloading UVM: {e}")

if __name__ == "__main__":
    download_uvm()
