import sys, subprocess, os

target_paper = sys.argv[1]

tmp_dir = os.environ["TMP_DIR"]

title_from_pdfinfo_cmd = 'pdfinfo "' + target_paper +  '" | head -1'
title_from_pdfinfo_output = subprocess.check_output(title_from_pdfinfo_cmd, shell=True)
title_from_pdfinfo_output = title_from_pdfinfo_output.strip()

title_index = title_from_pdfinfo_output.index('Title:')
title_from_pdfinfo_output = title_from_pdfinfo_output[title_index+6:]
title_from_pdfinfo_output = title_from_pdfinfo_output.strip()

if title_from_pdfinfo_output == "" or len(title_from_pdfinfo_output) < 8:
    generate_papertxt_cmd = 'pdftotext -raw "' + target_paper + '" "'  + tmp_dir + '/paper_text.txt"'
    generate_papertxt_output = subprocess.check_output(generate_papertxt_cmd, shell=True)
    generate_papertxt_output = generate_papertxt_output.strip()

    first_line_cmd = 'cat "' + tmp_dir + '/paper_text.txt" | head -1'
    first_line_output = subprocess.check_output(first_line_cmd, shell=True)
    first_line_output = first_line_output.strip()

    print(first_line_output)
else:
    print(title_from_pdfinfo_output)