import os
import shutil
import time


def get_modification_date(file):

	modification_date = ''

	file_name = os.path.basename(file)

	if file_name.startswith('Screen Shot '):
		modification_date = file_name[12:19].replace('-', '.')
	elif file_name.startswith('Screenshot from '):
		modification_date = file_name[16:23].replace('-', '.')
	else:
		modification_time = os.path.getmtime(file)
		# Converting the time in seconds to a timestamp
		m_ti = time.ctime(modification_time)
		t_obj = time.strptime(m_ti)
		# Transforming the time object to a timestamp
		# of ISO 8601 format
		modification_date = time.strftime("%Y.%m", t_obj)

	return modification_date

def organize_files(target_dir):

	base_dir = target_dir
	files = os.listdir(target_dir)

	for index, file in enumerate(files):
		file_path = os.path.join(base_dir, file)
		if os.path.isfile(file_path):
			modification_date = get_modification_date(file_path)
			target_folder = os.path.join(base_dir, modification_date)
			print(f"> Moving file \n\t{file_path}\nto folder\n\t{target_folder}")

			if not os.path.exists(target_folder):
				os.makedirs(target_folder)

			shutil.move(file_path, target_folder)

if __name__ == '__main__':
	import sys

	target_dir = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()

	organize_files(target_dir)
