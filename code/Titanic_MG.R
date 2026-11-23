# ==========================================
# Project: Titanic Data Analysis
# Name: Maria Garcia
# Date: November 22, 2026
# Course: CSCI 5103 - Module 7
# Purpose: Analyze Titanic passenger survival based on gender and passenger ticket class.
# ==========================================


# Load required packages
library(tidyverse)  # For data manipulation and ggplot2
library(here)       # For managing file paths

# Verify the here() package finds your project root correctly
here()  # Should show the path to your Exercise Files folder

# Import data using here() for reproducible file paths
titanic <- read_csv(here("data", "train.csv"))

# Examine the structure of the data
glimpse(titanic)
summary(titanic)
head(titanic)

# Check for missing values in the dataset
colSums(is.na(titanic))


# The dataset contains missing values in Age, Cabin, and Embarked.
# Analyses 1 and 2 use all 891 passengers because their variables have no missing values.
# Analysis 3 excludes 177 passengers with missing ages, leaving 714 passengers.



################################################################################
# Analysis 1: Gender and Survival
################################################################################

# Research Question: Were female passengers more likely to survive the Titanic disaster than male passengers?

################################################################################

# Group passengers by gender and calculate the total passengers, survivors, and survival rates.
gender_summary <- titanic %>%
  group_by(Sex) %>%
  summarise(
    TotalPassengers = n(),
    Survivors = sum(Survived),
    SurvivalRate = mean(Survived) * 100,
    .groups = "drop"
  )

# Display the results.
print(gender_summary)


# Create a bar chart comparing survival rates between female and male passengers.
gender_plot <- ggplot(
  gender_summary,
  aes(x = Sex, y = SurvivalRate, fill = Sex)
) +
  geom_col(width = 0.6) +
  geom_text(
    aes(label = paste0(round(SurvivalRate, 1), "%")),
    vjust = -0.5
  ) +
  scale_fill_manual(
    values = c(
      "female" = "#E9A5C9",
      "male" = "#729ECE"
    )
  ) +
  scale_y_continuous(limits = c(0, 100)) +
  labs(
    title = "Titanic Survival Rate by Gender",
    x = "Passenger Gender",
    y = "Survival Rate (%)",
    fill = "Gender",
    caption = "Source: Titanic train.csv dataset"
  ) +
  theme_minimal()

# Display the bar chart.
print(gender_plot)


# Perform a chi square test to determine whether gender and survival status are associated.
gender_table <- table(titanic$Sex, titanic$Survived)

gender_test <- chisq.test(gender_table)

# Display the statistical test results.
print(gender_test)

# Check expected counts for the chi square test.
print(gender_test$expected)


# Interpretation:
# Female passengers had a survival rate of approximately 74.2%, compared with 18.9% for male passengers.
#
# The bar chart shows that female passengers had substantially higher survival rates than male passengers.
#
# The chi square test provides strong statistical evidence of an association between gender and survival status p < 0.001.
#
# One possible explanation is that women and children were prioritized during evacuation.
#
# This result was expected because of the historical practice of prioritizing women and children, 
# although the large difference in survival rates was surprising.



################################################################################
# Analysis 2: Ticket Class and Survival
################################################################################

# Research Question: Was passenger ticket class associated with survival rates during the Titanic disaster?

################################################################################

# Group passengers by ticket class and calculate the total passengers, survivors, and survival rates.
class_summary <- titanic %>%
  group_by(Pclass) %>%
  summarise(
    TotalPassengers = n(),
    Survivors = sum(Survived),
    SurvivalRate = mean(Survived) * 100,
    .groups = "drop"
  )

# Display the results.
print(class_summary)


# Give the ticket classes readable names.
ticket_class <- factor(
  titanic$Pclass,
  levels = c(1, 2, 3),
  labels = c(
    "First Class",
    "Second Class",
    "Third Class"
  )
)

# Give survival outcomes readable names.
survival_status <- factor(
  titanic$Survived,
  levels = c(0, 1),
  labels = c(
    "Did Not Survive",
    "Survived"
  )
)

# Create a table of passenger counts for each ticket class and survival status.
class_table <- table(
  TicketClass = ticket_class,
  SurvivalStatus = survival_status
)

# Display the table.
print(class_table)


# Calculate survival percentages within each ticket class for the mosaic style plot.
mosaic_data <- titanic %>%
  count(Pclass, Survived) %>%
  group_by(Pclass) %>%
  mutate(
    Percent = n / sum(n) * 100,
    Proportion = n / sum(n)
  ) %>%
  ungroup()


# Calculate rectangle widths based on the number of passengers in each class.
class_widths <- titanic %>%
  count(Pclass) %>%
  mutate(
    Width = n / sum(n),
    Xmax = cumsum(Width),
    Xmin = Xmax - Width,
    Xcenter = (Xmin + Xmax) / 2
  ) %>%
  select(Pclass, Xmin, Xmax, Xcenter)


# Combine rectangle widths and survival percentages.
# Calculate positions for the percentage labels.
mosaic_data <- mosaic_data %>%
  left_join(class_widths, by = "Pclass") %>%
  arrange(Pclass, Survived) %>%
  group_by(Pclass) %>%
  mutate(
    Ymax = cumsum(Proportion),
    Ymin = Ymax - Proportion,
    Ycenter = (Ymin + Ymax) / 2,
    SurvivalStatus = if_else(
      Survived == 1,
      "Survived",
      "Did Not Survive"
    )
  ) %>%
  ungroup()


# Create a mosaic style plot comparing survival outcomes across passenger classes.
# Red represents passengers who did not survive.
# Green represents passengers who survived.
class_plot <- ggplot(mosaic_data) +
  geom_rect(
    aes(
      xmin = Xmin,
      xmax = Xmax,
      ymin = Ymin,
      ymax = Ymax,
      fill = SurvivalStatus
    ),
    color = "white",
    linewidth = 2
  ) +
  geom_text(
    aes(
      x = Xcenter,
      y = Ycenter,
      label = paste0(round(Percent, 1), "%")
    ),
    size = 4,
    color = "black"
  ) +
  scale_fill_manual(
    values = c(
      "Did Not Survive" = "#E57373",
      "Survived" = "#4CAF50"
    )
  ) +
  scale_x_continuous(
    breaks = class_widths$Xcenter,
    labels = c(
      "First Class",
      "Second Class",
      "Third Class"
    ),
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    labels = scales::percent,
    expand = c(0, 0)
  ) +
  labs(
    title = "Titanic Survival by Ticket Class",
    x = "Passenger Ticket Class",
    y = "Percentage Within Class",
    fill = "Survival Status",
    caption = "Source: Titanic train.csv dataset"
  ) +
  theme_minimal()

# Display the mosaic style plot.
print(class_plot)


# Perform a chi square test to determine whether ticket class and survival status are associated.
class_test <- chisq.test(class_table)

# Display the statistical test results.
print(class_test)

# Check expected counts for the chi square test.
print(class_test$expected)


# Interpretation:
# First class passengers had the highest survival rate at approximately 63.0%.
#
# Second class passengers had a survival rate of approximately 47.3%.
#
# Third class passengers had the lowest survival rate at approximately 24.2%.
#
# The mosaic style plot shows that first class passengers had the largest proportion of survivors,
# while third class passengers had the largest proportion of non survivors.
#
# The rectangle widths represent the proportion of passengers in each class, 
# while the heights represent survival percentages within each class.
#
# The chi square test provides strong statistical evidence of an association between ticket class and survival status p < 0.001.
#
# One possible explanation is that cabin locations and access to evacuation areas differed between passenger classes.
#
# The pattern was expected because first class passengers may have had easier access to evacuation areas.
#
# However, the large difference between first class and third class survival rates was surprising.


################################################################################
# ANALYSIS 3: AGE AND SURVIVAL
################################################################################

# Research Question: Did passenger ages differ between those who survived and those who did not?

################################################################################

# Remove passengers with missing age values.
# Create readable labels for survival status.
age_data <- titanic %>%
  filter(!is.na(Age)) %>%
  mutate(
    SurvivalStatus = if_else(
      Survived == 1,
      "Survived",
      "Did Not Survive"
    )
  )

# Group passengers by survival status and calculate age statistics for each group.
age_summary <- age_data %>%
  group_by(SurvivalStatus) %>%
  summarise(
    TotalPassengers = n(),
    AverageAge = mean(Age),
    MedianAge = median(Age),
    .groups = "drop"
  )

# Display the calculated results.
print(age_summary)



# Create a boxplot comparing passenger ages by survival status.
age_plot <- ggplot(
  age_data,
  aes(
    x = SurvivalStatus,
    y = Age,
    fill = SurvivalStatus
  )
) +
  geom_boxplot(alpha = 0.8) +
  scale_fill_manual(
    values = c(
      "Did Not Survive" = "#E57373",
      "Survived" = "#4CAF50"
    )
  ) +
  labs(
    title = "Titanic Passenger Age by Survival",
    x = "Survival Status",
    y = "Passenger Age (Years)",
    fill = "Survival Status",
    caption = paste(
      "Source: Titanic train.csv;",
      "missing ages excluded"
    )
  ) +
  theme_minimal()

# Display the boxplot.
print(age_plot)



# Interpretation:
# The passengers who survived had an average age of approximately 28.3 years, compared to 30.6 years for those who did not survive.
# Both groups had a median age of 28 years.
# This suggests a modest difference in average age between the two groups.
# However, age alone does not explain passenger survival.
# Note: 177 passengers had missing age information and were excluded from this analysis.




# ==========================================
# FINAL CONCLUSION
# ==========================================

# Analysis 1 showed that female passengers had substantially higher survival rates than male passengers.
#
# Analysis 2 showed that first class passengers had higher survival rates than passengers traveling in second or third class.
#
# Analysis 3 showed that survivors were slightly younger on average than non-survivors, though both groups had the same median age of 28 years.
#
# These findings suggest that gender and ticket class were associated with survival,
# while age showed a smaller difference between survivors and non-survivors.
#
# These relationships do not necessarily mean that these passenger characteristics
# directly caused the differences in survival outcomes.
#
# The age analysis excluded 177 passengers with missing age information.
