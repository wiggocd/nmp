const owner = "wiggocd";
const repo = "nmp";
const downloadExtension = ".zip";

getLatestDownload();

function getLatestDownload() {
    const http = new XMLHttpRequest();
    const url = "https://api.github.com/repos/"+owner+"/"+repo+"/releases/latest";
    http.open("GET", url);
    http.send();

    http.onreadystatechange = (event) => {
        if (http.response != "") {
            var data = JSON.parse(http.response);
            var asset_url = "";

            try {
                const assets = data.assets;
                
                if (assets.length > 0) {
                    for (i in assets) {
                        const asset = assets[i]
                        if (asset.name.endsWith(downloadExtension)) {
                            asset_url = asset.browser_download_url
                            break;
                        }
                    }
                }
            } catch {
                console.log("Asset(s) not found");
            }

            const element = document.getElementById("download-latest")
            if (element && element.hasAttribute("href")) {
                element.href = asset_url
            }
        }
    }
}