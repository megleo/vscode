from typing import List
import sys
import requests
import gitlab
requests.packages.urllib3.disable_warnings()

from sdkgit.product_info import ReleaseInfo, ProjectInfo
from tools.utils import printf
from tools.config import *
from tools.utils import ask


def get_projects():
    try:
        gl = gitlab.Gitlab.from_config('git', [TOKEN_PATH])
        gl.auth()
        projects = gl.projects.list(search='T-AIStack', all=True)
        return projects
    except gitlab.exceptions.GitlabAuthenticationError:
        os.system("rm -rf " + TOKEN_PATH)
        printf("Token expired. Please use command \"sdkmanager --init\" to initialize.", style="RED")
        sys.exit(0)
    except gitlab.config.GitlabConfigMissingError:
        os.system("rm -rf " + TOKEN_PATH)
        printf("sdkmanager app is not initialized. Please use command \"sdkmanager --init\" to initialize first.", style="RED")
        sys.exit(0)
    except requests.exceptions.ConnectTimeout:
        printf("The network connection timed out. Please try again later.", style="RED")
        sys.exit(0)
    except Exception as e:
        printf("Exception: " + e.__class__.__name__ + ". Please try again later.", style="RED")
        sys.exit(0)


def get_sdks(projects):
    printf("Getting information, please wait ...", style="INFO")
    sdks_info = []
    for project in projects:
        project_name = project.path_with_namespace.split("/")[0]
        releases = project.releases.list()
        for release in releases:
            sdk_list = []
            for i in range(0, len(release.assets['links'])):
                release_url = release.assets['links'][i]['url']
                sdk_list.append(release_url)
            sdks_info.extend(sdk_list)
    return sdks_info

def sort_info(sdks_info)->[]:
    snpe = [{snpe.split("/")[-1] : snpe} for snpe in sdks_info if snpe.split("/")[-1].startswith("SNPE")]
    qnn = [{qnn.split("/")[-1] : qnn} for qnn in sdks_info if qnn.split("/")[-1].startswith("QNN")]
    Hexagon = [{hexagon.split("/")[-1] : hexagon} for hexagon in sdks_info if hexagon.split("/")[-1].startswith("HexagonSDK")]
    return [snpe, qnn, Hexagon]

def select_img(projects_img_info: List):
    if len(projects_img_info) == 0:
        printf("You have not activated any product rights, so you cannot download released sdks.", style="RED")
        printf("Please contact service@thundercomm.com to open the relevant product permissions.", style="RED")
        sys.exit(0)
    try:
        printf("\nProjects options are as follows", style="RED")
        for i, project in enumerate(projects_img_info):
            printf("...." + str(i + 1) + ". " + project.project_name)
        printf("Which product would you like?    [Enter the number]:", style="GREEN")
        product_select = int(input())
        project = projects_img_info[product_select - 1]

        if len(project.releases) == 0:
            printf("{} has no released version yet.".format(project.project_name), style="INFO")
            printf("EXIT.", style="GREEN")
            sys.exit(0)

        printf("\nSDK Images release options are as follows:", style="RED")
        for j, release in enumerate(project.releases):
            printf("...." + str(j + 1) + ". " + release.release_name + " (" + release.release_data + ")")
        printf("Which SDK releases you like?     [Enter the number]:", style="GREEN")
        release_select = int(input())
        release = project[release_select - 1]

        if len(release.image_list) == 0:
            printf("{} has no released version yet.".format(release.release_name), style="INFO")
            printf("EXIT.", style="GREEN")
            sys.exit(0)

        printf("\nSDK image options are as follows:", style="RED")
        for z in range(len(release.image_list)):
            printf("...." + str(z + 1) + ". " + release[z].split('/')[-1])
        printf("Which images would you like?     [Enter the number]:", style="GREEN")
        image_select = int(input())
        url = release[image_select - 1]
        default_download_path = os.path.join(DOWNLOAD_PATH_IMG, "")
        input_path = str(input(
            "\033[32mInput a relative path(/home/turbox/workspace/<\033[1mrelative path\033[0m\033[32m>) for sdk image or"
            " input 'Enter' to select the default directory:"
            + default_download_path + "):\033[0m"))
        if input_path == "":
            download_path = default_download_path
        else:
            for path in input_path.split("/"):
                if len(path) > 255:
                    printf("Filename too long.", style="INFO")
                    printf("EXIT.", style="INFO")
                    sys.exit()
            download_path = os.path.join(WORKSPACE, input_path.lstrip("/"))
        return download_path, url
    except IndexError:
        printf("Your Entered number is out of selection range.", style="INFO")
        sys.exit(0)
    except ValueError:
        printf("Please enter Arabic numerals.", style="INFO")
        sys.exit(0)


# download_path, project_name, release_name, image
def download_img(path, url):
    option = ask("Are you sure to download the image to " + path + " ?")
    if not option:
        printf("Please run the sdkmanager again.", style="INFO")
        sys.exit(0)
    if not os.path.exists(path):
        printf("mkdir " + path, style="CMD")
        os.makedirs(path)

    file_path = path + url.split('/')[-1]
    r1 = requests.get(url, stream=True, verify=False)
    total_size = int(r1.headers['Content-Length'])

    if os.path.exists(file_path):
        printf("Starting download base on the previously download file ... ", style="INFO")
    else:
        printf("Starting download {} to {} ...".format(url.split('/')[-1], path))

    os.chdir(path)
    cmd = "wget -c -q --show-progress --tries=10 " + url
    printf(cmd, style="CMD")
    os.system(cmd)

    if os.path.exists(file_path):
        temp_size = os.path.getsize(file_path)
        if temp_size == total_size:
            printf("Download Success.", style="INFO")
            printf("Image path: {} .".format(file_path), style="INFO")
            sys.exit(0)

    printf("Download  failed.", style="INFO")


def gitlab_download_img():
    proj = get_projects()
    sdks_info = get_sdks(proj)
    sort_infos = sort_info(sdks_info)
    for sdks_info in sort_infos:
        print(sdks_info)
    # path, url = select_img(project_list)
    # download_img(path, url)

