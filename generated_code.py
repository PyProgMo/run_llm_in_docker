import datetime
import time
import threading

events = []

def add_event():
    name = input("Enter event name: ")
    date_str = input("Enter date (YYYY-MM-DD): ")
    time_str = input("Enter time (HH:MM): ")
    reminder = int(input("Enter reminder minutes (default 10): ") or 10)
    event_datetime = datetime.datetime.strptime(date_str + ' ' + time_str, '%Y-%m-%d %H:%M')
    events.append({'name': name, 'datetime': event_datetime, 'reminder': reminder})
    print("Event added successfully!")

def check_reminders():
    now = datetime.datetime.now()
    for event in events:
        reminder_time = event['datetime'] - datetime.timedelta(minutes=event['reminder'])
        if reminder_time <= now < event['datetime']:
            print(f"\nReminder: Your event '{event['name']}' is in {event['reminder'] - (now - reminder_time).seconds//60} minutes!")

def run_reminder_checker():
    while True:
        check_reminders()
        time.sleep(60)

def main():
    print("Welcome to the Calendar App!")
    threading.Thread(target=run_reminder_checker, daemon=True).start()
    while True:
        print("\nOptions:")
        print("1. Add Event")
        print("2. Exit")
        choice = input("Choose an option: ")
        if choice == '1':
            add_event()
        elif choice == '2':
            print("Exiting the app.")
            break
        else:
            print("Invalid choice. Please try again.")

if __name__ == "__main__":
    main()