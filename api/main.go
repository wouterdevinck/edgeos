package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os/exec"
)

type statusResponse struct {
	EdgeOsVersion      string `json:"edgeos_version"`
	BootedFrom         string `json:"booted_from"`
	ApplicationName    string `json:"application_name"`
	ApplicationVersion string `json:"application_version"`
}

type upgradeRequest struct {
	Url string `json:"url"`
}

// TODO Error handling

func statusHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-type", "Application/json")
	var status statusResponse
	osversion, _ := exec.Command("bash", "-c", "source current-boot > /dev/null; echo -n $CURRENT_EDGEOS_VERSION").Output()
	status.EdgeOsVersion = string(osversion)
	boot, _ := exec.Command("bash", "-c", "source current-boot > /dev/null; echo -n $CURRENT_BOOT").Output()
	status.BootedFrom = string(boot)
	name, _ := exec.Command("bash", "-c", "source read-manifest /boot/manifest/manifest.json > /dev/null; echo -n $APP_NAME").Output()
	status.ApplicationName = string(name)
	version, _ := exec.Command("bash", "-c", "source read-manifest /boot/manifest/manifest.json > /dev/null; echo -n $APP_VERSION").Output()
	status.ApplicationVersion = string(version)
	jsonBytes, _ := json.Marshal(status)
	w.WriteHeader(http.StatusOK)
	w.Write(jsonBytes)
}

func rebootHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		w.WriteHeader(http.StatusOK)
		exec.Command("reboot").Run()
	}
}

func switchBootHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		exec.Command("switch-boot").Run()
		w.WriteHeader(http.StatusOK)
	}
}

// TODO Status reporting
func upgradeHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		decoder := json.NewDecoder(r.Body)
		var req upgradeRequest
		err := decoder.Decode(&req)
		if err == nil {
			exec.Command("online-upgrade", req.Url).Run()
		}
	}
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/status", statusHandler)
	mux.HandleFunc("/reboot", rebootHandler)
	mux.HandleFunc("/switch", switchBootHandler)
	mux.HandleFunc("/upgrade", upgradeHandler)
	log.Fatal(http.ListenAndServe(":7994", mux))
}
