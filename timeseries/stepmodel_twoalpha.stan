data {
  int<lower=0> N_long;
  int<lower=0> N_short;
  vector[N_long] time_long;
  vector[N_long] value_long;
  vector[N_short] time_short;
  vector[N_short] value_short;
}

parameters {
  real alpha_long;
  real beta_long;
  real<lower=0> sigma_long;
  real alpha_short_before;
  real beta_short_before;
  real alpha_short_after;
  real beta_short_after;
  real<lower=0> sigma_short;
  real<lower=min(time_short), upper=max(time_short)> step_time;  // Step time as a parameter
}

model {
  // Priors for long-term trend
  alpha_long ~ normal(0, 10);
  beta_long ~ normal(0, 10);
  sigma_long ~ cauchy(0, 2);
  
  // Long-term trend likelihood
  value_long ~ normal(alpha_long + beta_long * time_long, sigma_long);
  
  // Priors for short-term trend
  alpha_short_before ~ normal(alpha_long, 5);
  beta_short_before ~ normal(beta_long, 5);
  alpha_short_after ~ normal(alpha_long, 5);
  beta_short_after ~ normal(beta_long, 5);
  sigma_short ~ cauchy(0, 2);
  
  // Prior for step_time
  step_time ~ uniform(min(time_short), max(time_short));
  
  // Short-term trend likelihood with step change
  for (i in 1:N_short) {
    if (time_short[i] < step_time) {
      value_short[i] ~ normal(alpha_short_before + beta_short_before * time_short[i], sigma_short);
    } else {
      value_short[i] ~ normal(alpha_short_after + beta_short_after * time_short[i], sigma_short);
    }
  }
}
