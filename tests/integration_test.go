package tests

import (
	"context"
	"fmt"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/google/go-containerregistry/pkg/name"
	"github.com/google/go-containerregistry/pkg/v1/remote"
	"github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/require"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// TestBasic will verify that traffic can ingress into the cluster and the cluster can use the local container registry
func TestBasic(t *testing.T) {
	// Remember that you can skip any particular stage by setting `SKIP_<name>` environment variable
	dir := setup(t, "examples/basic", map[string]interface{}{
		"registry_port": k8s.GetAvailablePort(t),
		"http_port":     k8s.GetAvailablePort(t),
	})

	test_structure.RunTestStage(t, "TEST", func() {
		tfOptions := test_structure.LoadTerraformOptions(t, dir)
		k8sOptions := &k8s.KubectlOptions{
			ConfigPath: terraform.Output(t, tfOptions, "kubeconfig"),
		}

		var ports map[string]map[string]int
		terraform.OutputStruct(t, tfOptions, "ingress_ports", &ports)

		k8s.AreAllNodesReady(t, k8sOptions)

		k8s.KubectlApply(t, k8sOptions, "./testdata/ingress.yaml")

		client, err := k8s.GetKubernetesClientFromOptionsE(t, k8sOptions)
		if err != nil {
			t.Fatal(err)
		}

		retry.DoWithRetry(t, "WaitForNginxIngress", 20, 5*time.Second, func() (string, error) {
			dep, err := client.AppsV1().Deployments("ingress-nginx").Get(context.Background(), "ingress-nginx-controller", metav1.GetOptions{})
			if err != nil {
				return "", err
			}

			if dep.Status.ReadyReplicas < 1 {
				return "", fmt.Errorf("no replicas ready: %#v", dep.Status)
			}

			return strconv.Itoa(int(dep.Status.ReadyReplicas)), nil
		})

		newRef, err := name.ParseReference(fmt.Sprintf("%s/hashicorp/http-echo:0.2.3", terraform.Output(t, tfOptions, "registry_url")), name.Insecure)
		require.NoError(t, err)

		img, err := remote.Image(name.MustParseReference("docker.io/hashicorp/http-echo:0.2.3"))
		require.NoError(t, err)

		require.NoError(t, remote.Write(newRef, img))

		data, err := os.ReadFile("./testdata/demo.yaml")
		require.NoError(t, err)

		manifests := strings.ReplaceAll(string(data), "__IMAGE__", newRef.String())

		k8s.KubectlApplyFromString(t, k8sOptions, manifests)

		k8s.WaitUntilIngressAvailable(t, k8s.NewKubectlOptions(k8sOptions.ContextName, k8sOptions.ConfigPath, "default"), "example-ingress", 10, 5*time.Second)

		http_helper.HttpGetWithValidation(t, fmt.Sprintf("http://localhost:%d/foo", ports["http"]["host"]), nil, 200, "foo")
	})
}

// TestRepoOptional will verify that the registry part is optional
func TestRepoOptional(t *testing.T) {
	// Remember that you can skip any particular stage by setting `SKIP_<name>` environment variable
	dir := setup(t, "examples/registry_optional", map[string]interface{}{
		"http_port": k8s.GetAvailablePort(t),
	})

	test_structure.RunTestStage(t, "TEST", func() {
		tfOptions := test_structure.LoadTerraformOptions(t, dir)
		k8sOptions := &k8s.KubectlOptions{
			ConfigPath: terraform.Output(t, tfOptions, "kubeconfig"),
		}

		k8s.AreAllNodesReady(t, k8sOptions)
	})
}

func setup(t *testing.T, moduleDir string, vars map[string]interface{}) string {
	dir := test_structure.CopyTerraformFolderToTemp(t, "..", moduleDir)

	t.Logf("Terraform directory is %s", dir)

	test_structure.RunTestStage(t, "CONFIG", func() {
		test_structure.SaveTerraformOptions(t, dir, &terraform.Options{
			TerraformDir: dir,
			Vars:         vars,
		})
	})

	test_structure.RunTestStage(t, "INIT", func() {
		options := test_structure.LoadTerraformOptions(t, dir)
		terraform.Init(t, options)
	})

	t.Cleanup(func() {
		test_structure.RunTestStage(t, "DESTROY", func() {
			options := test_structure.LoadTerraformOptions(t, dir)
			terraform.Destroy(t, options)
		})
	})

	test_structure.RunTestStage(t, "APPLY", func() {
		options := test_structure.LoadTerraformOptions(t, dir)
		terraform.ApplyAndIdempotent(t, options)
	})

	return dir
}
