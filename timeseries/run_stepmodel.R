
library(bayesplot)
library(tidyverse)
library(rstan)
library(brms)

# Example data with noise and step change
set.seed(123)  # For reproducibility

long_term_data <- data.frame(
  time = c(1, 10, 20),
  value = c(10, 10, 10) + rnorm(3, mean = 0, sd = 2) 
)

short_term_data <- data.frame(
  time = 18:27,
  value = c(10, 10, 10, 10, 10, 25, 27, 29, 31, 32) + rnorm(10, mean = 0, sd = 1)  # Adding noise with sd = 1
)

plot(long_term_data, 
     type = "o", col = "blue", 
     xlab = "Time", ylab = "EBV Response",
     xlim = c(0,27), ylim = c(0,35))
points(short_term_data, type = "o", col = "red")

# Stan model
#================

# Prepare data for Stan
stan_data <- list(
  N_long = nrow(long_term_data),
  N_short = nrow(short_term_data),
  time_long = long_term_data$time,
  value_long = long_term_data$value,
  time_short = short_term_data$time,
  value_short = short_term_data$value
)

# Fit the model
## ! note: a first trial 'stepmodel.stan' did not include separate intecepts

fit <- stan(
  file = 'timeseries/stepmodel_twoalpha.stan',
  data = stan_data,
  iter = 2000,
  chains = 4
)

# Print the results
print(fit)

# plot posterior
#==================

# Extract posterior samples
posterior_samples <- extract(fit)

beta_long_samples <- posterior_samples$beta_long
beta_short_before_samples <- posterior_samples$beta_short_before
beta_short_after_samples <- posterior_samples$beta_short_after
step_time_samples <- posterior_samples$step_time

# Plot the posterior distributions
mcmc_areas(
  as.matrix(data.frame(beta_short_before = beta_short_before_samples, 
                       beta_short_after = beta_short_after_samples, 
                       beta_long_samples = beta_long_samples)),
  pars = c("beta_short_before", "beta_short_after", "beta_long_samples"),
  prob = 0.95  # 95% credible intervals
)


# Plot with the raw data
#==========================

# Extract posterior samples
posterior_samples <- extract(fit)

alpha_long_samples <- posterior_samples$alpha_long
beta_long_samples <- posterior_samples$beta_long
alpha_short_before_samples <- posterior_samples$alpha_short_before
beta_short_before_samples <- posterior_samples$beta_short_before
alpha_short_after_samples <- posterior_samples$alpha_short_after
beta_short_after_samples <- posterior_samples$beta_short_after
step_time_samples <- posterior_samples$step_time

# Calculate the mean of the posterior samples for plotting
alpha_long_mean <- mean(alpha_long_samples)
beta_long_mean <- mean(beta_long_samples)
alpha_short_before_mean <- mean(alpha_short_before_samples)
beta_short_before_mean <- mean(beta_short_before_samples)
alpha_short_after_mean <- mean(alpha_short_after_samples)
beta_short_after_mean <- mean(beta_short_after_samples)
step_time_mean <- mean(step_time_samples)

# Generate estimated values from the model for long-term trend
estimated_values_long_term <- alpha_long_mean + beta_long_mean * long_term_data$time

# Generate estimated values from the model for short-term trend
estimated_values_short_term <- sapply(short_term_data$time, function(t) {
  if (t < step_time_mean) {
    return(alpha_short_before_mean + beta_short_before_mean * t)
  } else {
    return(alpha_short_after_mean + beta_short_after_mean * t)
  }
})

# Combine the data for plotting
plot_data <- data.frame(
  time = c(long_term_data$time, short_term_data$time),
  value = c(long_term_data$value, short_term_data$value),
  type = c(rep("Long-term Data", nrow(long_term_data)), rep("Short-term Data", nrow(short_term_data)))
)

estimated_data_long_term <- data.frame(
  time = long_term_data$time,
  value = estimated_values_long_term,
  type = rep("Estimated Long-term Values", length(estimated_values_long_term))
)

estimated_data_short_term <- data.frame(
  time = short_term_data$time,
  value = estimated_values_short_term,
  type = rep("Estimated Short-term Values", length(estimated_values_short_term))
)

# Plot the time series data and the estimated values from the model
steptime_model<-ggplot() +
  geom_point(data = plot_data, aes(x = time, y = value, color = type)) +
  geom_line(data = plot_data, aes(x = time, y = value, color = type)) +
  geom_line(data = estimated_data_long_term, aes(x = time, y = value, color = type), linetype = "dashed") +
  geom_line(data = estimated_data_short_term, aes(x = time, y = value, color = type), linetype = "dashed") +
  geom_vline(xintercept = step_time_mean, linetype = "dotted", color = "black") +
  labs(title = "Time Series Data and Estimated Values from the Model", x = "Time", y = "Value") +
  scale_color_manual(values = c("Long-term Data" = "red", "Short-term Data" = "green", "Estimated Long-term Values" = "red", "Estimated Short-term Values" = "green")) +
 ylab("Community-level metric (e.g. proportion of generalists)")+
  theme_bw()+
  theme(legend.title= element_blank())

ggsave("steptime_model.png", width = 6, height = 4)

