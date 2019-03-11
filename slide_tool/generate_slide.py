import os
import shutil

slide_name = os.path.basename(os.getcwd()) + ".html"

template_file = "slide_template.html"
src_template_file = os.environ["CONFIG_FILES_DIR"] + "/slide_tool/slide_template.html"

if not os.path.exists(template_file):
    shutil.copyfile(src_template_file, template_file)

content_lines = []
slide_lines = []

with open("tmp_content.txt", 'r') as f:
    content_lines = f.readlines()

with open(template_file, 'r') as f:
    slide_lines = f.readlines()

content = ''

for c in content_lines:
    content += c + "\n"

new_slide_content = []

for s in slide_lines:
    if '$SLIDES_CONTENT_FROM_MARKDOWN$' in s:
        new_slide_content.append(content)
    else:
        new_slide_content.append(s)

with open(slide_name, 'w') as f:
    for s in new_slide_content:
        f.write(s + "\n")

os.remove(template_file)
