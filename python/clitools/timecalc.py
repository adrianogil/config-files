

def is_number(s):
	return s in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']


def is_operand(s):
	return s in ['+', '-']


def calculate_sum(expression):
	total_minutes = expression["operand_a"]["minutes"] + expression["operand_b"]["minutes"]
	
	add_hours = total_minutes // 60
	total_minutes = total_minutes % 60

	total_hours = expression["operand_a"]["hours"] + expression["operand_b"]["hours"] + add_hours

	return {
		"hours": total_hours,
		"minutes": total_minutes 
	}


def calculate_subtraction(expression):
	total_minutes_a = expression["operand_a"]["hours"] * 60 + expression["operand_a"]["minutes"]
	total_minutes_b = expression["operand_b"]["hours"] * 60 + expression["operand_b"]["minutes"]
	
	result_minutes = total_minutes_a - total_minutes_b

	return {
		"hours": result_minutes // 60,
		"minutes": result_minutes % 60 
	}


def calculate_time_expression(expression):
	if "operand" in expression["operand_a"]:
		expression["operand_a"] = calculate_time_expression(expression["operand_a"])
	if "operand" in expression["operand_b"]:
		expression["operand_b"]  =calculate_time_expression(expression["operand_b"])

	if expression["operand"] == "+":
		return calculate_sum(expression)
	if expression["operand"] == "-":
		return calculate_subtraction(expression)


def  get_resulting_time_expression(time_expression):
	
	# Parse time expression
	current_number = ''
	current_time = {}
	current_expression = None
	for s in time_expression:
		if is_number(s):
			current_number += s
		elif s == 'h':
			current_time['hours'] = int(current_number)
			current_number = ""
		elif current_number != "":
			current_time["minutes"] = int(current_number)
			current_number = ""
			if current_expression:
				current_expression["operand_b"] = current_time
		elif "hours" in current_time:
			current_time["minutes"] = 0

		if is_operand(s):
			if current_expression:
				current_time = current_expression
			current_expression = {}
			current_expression["operand"] = s
			current_expression['operand_a'] = current_time
			current_time = {}
	if current_number != "":
		current_time["minutes"] = int(current_number)
		current_number = ""
		if current_expression:
			current_expression["operand_b"] = current_time
	elif "hours" in current_time:
		current_time["minutes"] = 0
		if current_expression:
			current_expression["operand_b"] = current_time

	# Calculate expression
	result = calculate_time_expression(current_expression)

	return "%dh%02d" % (result["hours"], result["minutes"])


if __name__ == '__main__':
	import sys
	time_expression = sys.argv[1]
	result = get_resulting_time_expression(time_expression)
	print(result)
